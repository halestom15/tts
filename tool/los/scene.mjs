// Extracts a line of sight scene from a TTS save, for run_scene.lua:
//
//   node tool/los/scene.mjs <save.json> --attacker <leader GUID> \
//     --target <leader GUID> [--out .los-scene]
//
// Writes <out>/scene.lua (terrain, minis, POIs, the attack) and caches every
// terrain and vehicle mesh in <out>/meshes. Bounds come from the meshes,
// X-mirrored the way TTS loads OBJ files. Asset bundles have no readable
// shape and are skipped (with a warning): the offline run can't judge them.

import { createHash } from 'crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const args = process.argv.slice(2);
const option = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : fallback;
};
const savePath = args[0];
const attacker = option('--attacker');
const target = option('--target');
const out = option('--out', '.los-scene');
if (!savePath || !attacker || !target) {
  console.error(
    'Usage: node tool/los/scene.mjs <save.json> --attacker <GUID> --target <GUID> [--out dir]',
  );
  process.exit(1);
}

const save = JSON.parse(readFileSync(savePath, 'utf8'));
mkdirSync(join(out, 'meshes'), { recursive: true });

// Battlefield footprint: the battlefield scripting zone, else the default.
const zoneState = save.ObjectStates.find((o) => o.GUID === 'cbc575');
const zone = zoneState
  ? zoneState.Transform
  : { posX: 8, posZ: 0, scaleX: 72, scaleZ: 48.4 };
const onBattlefield = (t) =>
  Math.abs(t.posX - zone.posX) <= zone.scaleX / 2 + 1 &&
  Math.abs(t.posZ - zone.posZ) <= zone.scaleZ / 2 + 1;

// Variables a spawned mini's script header sets (isAMini, unitType, ...).
function headerVars(script) {
  const vars = {};
  const guids = {};
  // The header comes first, so the first value seen for a name wins.
  const set = (k, v) => {
    if (!(k in vars)) vars[k] = v;
  };
  for (const line of (script || '').split('\n')) {
    let m = line.match(/^\s*(\w+)\s*=\s*"([^"]*)"\s*$/);
    if (m) set(m[1], m[2]);
    m = line.match(/^\s*(\w+)\s*=\s*(true|false|-?[\d.]+)\s*$/);
    if (m)
      set(
        m[1],
        m[2] === 'true' ? true : m[2] === 'false' ? false : Number(m[2]),
      );
    m = line.match(/^\s*miniGUIDs\[(\d+)\]\s*=\s*'(\w+)'/);
    if (m && !(m[1] in guids)) guids[m[1]] = m[2];
  }
  if (Object.keys(guids).length) vars.miniGUIDs = Object.values(guids);
  return vars;
}

// Mesh URL -> cached file, plus its bounds (min/max, before mirroring).
const meshes = new Map();
async function fetchMesh(url) {
  if (meshes.has(url)) return meshes.get(url);
  const file = join(
    out,
    'meshes',
    createHash('sha1').update(url).digest('hex').slice(0, 12) + '.obj',
  );
  if (!existsSync(file)) {
    const res = await fetch(
      url.replace(
        'http://cloud-3.steamusercontent.com',
        'https://steamusercontent-a.akamaihd.net',
      ),
    );
    if (!res.ok) throw new Error(`${res.status} for ${url}`);
    writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  }
  const min = [Infinity, Infinity, Infinity];
  const max = [-Infinity, -Infinity, -Infinity];
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    if (!line.startsWith('v ')) continue;
    const v = line.trim().split(/\s+/).slice(1, 4).map(Number);
    for (let i = 0; i < 3; i++) {
      min[i] = Math.min(min[i], v[i]);
      max[i] = Math.max(max[i], v[i]);
    }
  }
  const entry = { file, min, max };
  meshes.set(url, entry);
  return entry;
}

// Bounds at zero rotation, relative to the position, X mirrored as in TTS.
function boundsOf(mesh, scale) {
  const [x0, y0, z0] = mesh.min;
  const [x1, y1, z1] = mesh.max;
  return {
    center: {
      x: (-(x0 + x1) / 2) * scale.x,
      y: ((y0 + y1) / 2) * scale.y,
      z: ((z0 + z1) / 2) * scale.z,
    },
    size: {
      x: (x1 - x0) * scale.x,
      y: (y1 - y0) * scale.y,
      z: (z1 - z0) * scale.z,
    },
  };
}

const lua = (v) =>
  v === null || v === undefined
    ? 'nil'
    : typeof v === 'string'
    ? JSON.stringify(v)
    : typeof v === 'number' || typeof v === 'boolean'
    ? String(v)
    : Array.isArray(v)
    ? `{${v.map(lua).join(', ')}}`
    : `{${Object.entries(v)
        .map(([k, x]) => `[${JSON.stringify(k)}] = ${lua(x)}`)
        .join(', ')}}`;

const objects = [];
const skipped = [];
const minis = save.ObjectStates.filter(
  (o) => headerVars(o.LuaScript).isAMini === true,
);
const leaderOf = (o) => {
  const vars = headerVars(o.LuaScript);
  return save.ObjectStates.find((x) => x.GUID === vars.leaderGUID) || o;
};

for (const o of save.ObjectStates) {
  const t = o.Transform;
  if (!onBattlefield(t)) continue;
  const name = o.Nickname || '';
  const vars = headerVars(o.LuaScript);
  const isMini = vars.isAMini === true;
  const lower = name.toLowerCase();
  if (!isMini && (lower === 'table' || lower === 'battlefield')) continue;
  const unitType = isMini
    ? headerVars(leaderOf(o).LuaScript).unitType || ''
    : '';
  const needsShape = !isMini || unitType.includes('Vehicle');
  if (!['Custom_Model', 'Custom_Assetbundle'].includes(o.Name)) continue;
  const spec = {
    guid: o.GUID,
    name,
    type: o.Name,
    description: o.Description || '',
    pos: { x: t.posX, y: t.posY, z: t.posZ },
    rot: { x: t.rotX, y: t.rotY, z: t.rotZ },
    scale: { x: t.scaleX, y: t.scaleY, z: t.scaleZ },
    vars,
  };
  const url = o.CustomMesh && o.CustomMesh.MeshURL;
  if (needsShape && url) {
    spec.mesh = url;
    spec.bounds = boundsOf(await fetchMesh(url), spec.scale);
  } else if (needsShape) {
    skipped.push(`${name || o.GUID} (${o.Name})`);
    continue;
  }
  objects.push(spec);
}

// The template sizes silhouettes come from (StarWarsLegion.lua).
const global = readFileSync('mod/src/StarWarsLegion.lua', 'utf8');
const table = (name) => {
  const block = global.match(
    new RegExp(`templateInfo\\.${name} = \\{([\\s\\S]*?)\\n\\s*\\}`),
  );
  const values = {};
  for (const m of (block ? block[1] : '').matchAll(/(\w+)\s*=\s*([\d.]+)/g))
    values[m[1]] = Number(m[2]);
  return values;
};

const meshFiles = Object.fromEntries(
  [...meshes].map(([url, m]) => [url, m.file]),
);
writeFileSync(
  join(out, 'scene.lua'),
  `-- Generated by tool/los/scene.mjs from ${savePath}\nreturn ${lua({
    attacker,
    target,
    objects,
    meshFiles,
    baseRadius: table('baseRadius'),
    silhouetteHeight: table('silhouetteHeight'),
  })}\n`,
);
console.log(
  `Wrote ${join(out, 'scene.lua')}: ${objects.length} objects (${
    minis.length
  } minis in the save), ${meshes.size} meshes.`,
);
if (skipped.length) {
  console.warn(`Skipped (no readable shape offline): ${skipped.join(', ')}`);
}
