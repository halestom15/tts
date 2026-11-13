# Line of sight tools

Tools for working on the line of sight engine
(`mod/src/includes/LineOfSight.ttslua`). They need a standalone Lua (5.2 or
newer; `brew install lua`) and Node.

## Geometry tests

```sh
npm run test:los
```

Checks the engine's pure geometry against brute-force references, on generated
meshes (no network): OBJ parsing and X mirroring, the BVH line test, mesh
distances, vehicle outlines, cover parsing and sample points. The engine
exposes these functions in `LOS_TEST` only when a test sets
`LOS_EXPOSE_FOR_TESTS` before loading it.

## Replaying an attack from a save (offline)

```sh
node tool/los/scene.mjs <save.json> --attacker <leader GUID> --target <leader GUID>
lua tool/los/run_scene.lua [.los-scene] [--debug]
```

`scene.mjs` pulls the terrain, minis and POIs out of a TTS save and caches the
meshes in `.los-scene/`. `run_scene.lua` runs the engine on it against a small
fake TTS API (`fake_tts.lua`) and prints the lines, rings, panel and timing
(`--debug` adds the engine's per-mini log). Run `npm run generate` first so
the card data (Hover keyword) is available.

Offline limits: asset-bundle terrain has no readable shape and is skipped, and
`Physics.cast` isn't available, so judge those pieces in TTS.

## A running game

```sh
node tool/los/live.mjs status          # is the TTS Tools gateway connected?
node tool/los/live.mjs read            # lines, rings and panel as drawn now
node tool/los/live.mjs hotload         # load the engine into Global (memory only)
node tool/los/live.mjs rerun           # re-run the last ATTACK with it
node tool/los/live.mjs eval '<lua>'    # or eval @file.lua
```

Needs the [TTS Tools](https://marketplace.visualstudio.com/items?itemName=eunomiac.tts-tools)
VS Code extension: its gateway owns TTS's editor ports, and `live.mjs` goes
through the extension's MCP server, which returns Lua results. `hotload` keeps
the last attack, so `hotload` then `rerun` retests an engine change on the same
table; reloading the game undoes it.
