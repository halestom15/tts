-- Runs the line of sight engine on a scene from scene.mjs, outside TTS:
--
--   lua tool/los/run_scene.lua [scene dir] [--debug]
--
-- Builds the request the attacker's order token would send, runs the
-- verdict over simulated frames, and prints the lines, rings and panel.
-- Asset bundles were skipped by scene.mjs, and Physics.cast is not
-- available offline, so judge those pieces in TTS (live.mjs).

local dir, debug = ".los-scene", false
for _, a in ipairs(arg) do
  if a == "--debug" then debug = true else dir = a end
end

local fake = dofile("tool/los/fake_tts.lua")
local scene = dofile(dir .. "/scene.lua")

-- Card data, for the Hover keyword (built by `npm run generate`).
local ok = pcall(dofile, "mod/src/includes/generated/cards.ttslua")
fake.install(scene.meshFiles, ok and GENERATED_CARDS_SCHEMA or nil)
battlefieldZoneGUID = "cbc575"
fake.addObject({guid = "cbc575", name = "", pos = {x = 8, y = 24, z = 0}, rot = {x = 0, y = 0, z = 0},
  scale = {x = 72, y = 61, z = 48.4}})
for _, spec in ipairs(scene.objects) do
  fake.addObject(spec)
end
fake.addObject({guid = "losTok", name = "Order Token", pos = {x = 0, y = -50, z = 0},
  rot = {x = 0, y = 0, z = 0}, scale = {x = 1, y = 1, z = 1}})

-- The engine, with its debug log on if asked.
local src = fake.readFile("mod/src/includes/LineOfSight.ttslua")
if debug then src = src:gsub("local LOS_DEBUG = false", "local LOS_DEBUG = true", 1) end
assert(load(src, "LineOfSight.ttslua"))()

-- The silhouette a unit is judged by, as the order token's silhouetteOf.
local function silhouette(leader)
  local v = leader.getVar
  local size = v("baseSize") or "small"
  local r = (scene.baseRadius[size] or scene.baseRadius.small) / 2
  local h, o = scene.silhouetteHeight.small, 0
  if v("silhType") == "custom" then
    h = tonumber(v("silhHeight")) or scene.silhouetteHeight.custom
    o = tonumber(v("silhOffset")) or 0
  elseif size ~= "small" then
    h = scene.silhouetteHeight.notched
  end
  return {r = r, h = h, o = o}
end

local function minis(leader)
  local list = {}
  for _, guid in ipairs(leader.getVar("miniGUIDs") or {leader.getGUID()}) do
    local m = getObjectFromGUID(guid)
    if m then table.insert(list, {guid = guid, name = m.getName(), pos = m.getPosition()}) end
  end
  return list
end

local att, tgt = getObjectFromGUID(scene.attacker), getObjectFromGUID(scene.target)
assert(att and tgt, "attacker or target leader not found in the scene")
-- Minis never block rays: every mini, and every mini its leader lists (as
-- the order token's request does).
local all = {}
for _, o in ipairs(getAllObjects()) do
  if o.getVar("isAMini") == true then
    table.insert(all, o.getGUID())
    for _, guid in ipairs(o.getVar("miniGUIDs") or {}) do table.insert(all, guid) end
  end
end

for _, fn in ipairs(fake.timers) do fn() end -- background preparation
fake.settle()
local luaStart = fake.luaTime
losStartVerdict({
  gen = 1, tokenGuid = "losTok", leaderGuid = scene.attacker,
  attackerSil = silhouette(att), defenderSil = silhouette(tgt),
  attackers = minis(att), defenders = minis(tgt), miniGuids = all,
})
local frames = fake.settle()

local count = {}
for _, l in ipairs(fake.lines or {}) do
  local kind = #l.points > 2 and "ring" or "line"
  local c = l.color
  local color = (c[2] > 0.5 and c[1] < 0.5) and "green" or ((c[1] > 0.5 and c[2] > 0.5) and "yellow" or "red")
  count[kind .. " " .. color] = (count[kind .. " " .. color] or 0) + 1
end
print(string.format("%s -> %s: %d frames, %.0f ms of Lua", att.getName(), tgt.getName(), frames,
  (fake.luaTime - luaStart) * 1000))
for _, k in ipairs({"line green", "line red", "ring green", "ring yellow", "ring red"}) do
  if count[k] then print(string.format("  %-11s %d", k, count[k])) end
end
for _, id in ipairs({"losGreenCount", "losRedCount", "losCover", "losModelCounts"}) do
  print("  " .. id .. ": " .. tostring(fake.ui[id]))
end
