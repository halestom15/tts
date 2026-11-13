// Talks to a running TTS game through the TTS Tools VS Code extension
// (eunomiac.tts-tools), whose gateway owns TTS's editor ports. Uses the
// extension's MCP server, which waits for Lua return values.
//
//   node tool/los/live.mjs status
//   node tool/los/live.mjs eval '<lua>'      (or eval @file.lua)
//   node tool/los/live.mjs hotload           load LineOfSight.ttslua into Global (memory only)
//   node tool/los/live.mjs rerun             re-run the last ATTACK's verdict
//   node tool/los/live.mjs read              lines, rings and panel as drawn now
//
// hotload keeps the last attack, so `hotload` then `rerun` retests a change on
// the same table. Reloading the game undoes a hotload.

import { spawn } from 'child_process';
import { existsSync, readFileSync, readdirSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

function findServer() {
  const dir = join(homedir(), '.vscode', 'extensions');
  const ext =
    existsSync(dir) &&
    readdirSync(dir)
      .filter((d) => d.startsWith('eunomiac.tts-tools-'))
      .sort()
      .pop();
  if (!ext)
    throw new Error(
      'TTS Tools extension (eunomiac.tts-tools) not found in ~/.vscode/extensions',
    );
  return join(dir, ext, 'dist', 'mcp', 'server.js');
}

// One MCP tool call over stdio.
function callTool(name, args) {
  return new Promise((resolve, reject) => {
    const server = spawn('node', [findServer()], {
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    const pending = new Map();
    let buffer = '';
    server.stdout.on('data', (chunk) => {
      buffer += chunk;
      let newline;
      while ((newline = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, newline);
        buffer = buffer.slice(newline + 1);
        if (!line.trim()) continue;
        const msg = JSON.parse(line);
        if (pending.has(msg.id)) pending.get(msg.id)(msg);
      }
    });
    server.on('error', reject);
    const request = (id, method, params) =>
      new Promise((done) => {
        pending.set(id, done);
        server.stdin.write(
          JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n',
        );
      });
    (async () => {
      await request(1, 'initialize', {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'swlegion-los-tool', version: '1' },
      });
      server.stdin.write(
        JSON.stringify({
          jsonrpc: '2.0',
          method: 'notifications/initialized',
        }) + '\n',
      );
      const res = await request(2, 'tools/call', { name, arguments: args });
      server.kill();
      const text = ((res.result && res.result.content) || [])
        .map((c) => c.text)
        .join('');
      resolve(text ? JSON.parse(text) : res);
    })().catch((e) => {
      server.kill();
      reject(e);
    });
  });
}

async function lua(script) {
  const res = await callTool('tts_execute_lua', { script, maxWaitMs: 60000 });
  if (res.ok === false || res.error)
    throw new Error(res.error || JSON.stringify(res));
  return res.returnValue;
}

const READ = `
local out = {running = losVerdictRunning, lines = {}, panel = {}}
for _, id in ipairs({"losGreenCount", "losRedCount", "losCover", "losModelCounts"}) do
  out.panel[id] = UI.getValue(id)
end
for _, l in ipairs(Global.getVectorLines() or {}) do
  local c = l.color
  local color = (c.g > 0.5 and c.r < 0.5) and "green" or ((c.r > 0.5 and c.g > 0.5) and "yellow" or "red")
  local key = (#l.points > 2 and "ring " or "line ") .. color
  out.lines[key] = (out.lines[key] or 0) + 1
end
return JSON.encode(out)`;

const [command, arg] = process.argv.slice(2);
const commands = {
  status: async () => console.log(await callTool('tts_status', {})),
  eval: async () => {
    if (!arg) throw new Error('eval needs Lua code, or @file.lua');
    console.log(
      await lua(arg.startsWith('@') ? readFileSync(arg.slice(1), 'utf8') : arg),
    );
  },
  hotload: async () => {
    await lua(
      'losSavedRequest = losVerdictRequest and losVerdictRequest.request or losSavedRequest return true',
    );
    const engine = readFileSync('mod/src/includes/LineOfSight.ttslua', 'utf8');
    await lua(engine + '\nreturn "loaded"');
    console.log(
      'Loaded mod/src/includes/LineOfSight.ttslua into Global (memory only).',
    );
  },
  rerun: async () => {
    console.log(
      await lua(
        'local r = losSavedRequest or (losVerdictRequest and losVerdictRequest.request)\n' +
          'if not r then return "no attack to re-run" end\nlosStartVerdict(r)\nreturn "started"',
      ),
    );
  },
  read: async () =>
    console.log(JSON.stringify(JSON.parse(await lua(READ)), null, 2)),
};

if (!commands[command]) {
  console.error(
    'Usage: node tool/los/live.mjs status | eval <lua|@file> | hotload | rerun | read',
  );
  process.exit(1);
}
commands[command]().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
