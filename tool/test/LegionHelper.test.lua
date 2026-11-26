-- Tests for mod/src/includes/LegionHelper.ttslua, run with standalone Lua:
--
--   npm run test:lua
--
-- Cards already on the table take Legion Helper's art by name. A unit and an
-- upgrade can share a name (Clone Trooper Infantry and its Personnel upgrade):
-- each card must take its own art, the unit's card being the one its leader
-- names (cardGUID). Reported on Discord on 23 Nov 2026: the unit's card took
-- the Personnel upgrade's art.

-- Fake TTS ---------------------------------------------------------------

Wait = {
  frames = function(f, _) f() end,
  time = function(_, _) return 0 end,
}
broadcastToAll = function() end
require = function() end
Brain = function() return {} end
Global = {}

local spawned = {}
spawnObjectData = function(params) table.insert(spawned, params.data) end

startLuaCoroutine = function(_, name)
  local co = coroutine.create(_G[name])
  repeat
    local ok, err = coroutine.resume(co)
    assert(ok, err)
  until coroutine.status(co) == "dead"
end

local feedText
WebRequest = {
  get = function(_, callback) callback({text = feedText, is_error = false}) end,
}

local function card(guid, name, face)
  local obj = {type = "Card", destroyed = false}
  function obj.getGUID() return guid end
  function obj.getName() return name end
  function obj.isDestroyed() return obj.destroyed end
  function obj.destruct() obj.destroyed = true end
  function obj.getVar() return nil end
  function obj.getData()
    return {GUID = guid, Nickname = name, CustomDeck = {["1"] = {FaceURL = face, BackURL = face}}}
  end
  return obj
end

local function leader(cardGuid)
  local obj = {type = "Figurine"}
  function obj.getVar(name) if name == "cardGUID" then return cardGuid end end
  return obj
end

local objects = {}
getAllObjects = function() return objects end

-- The mod -----------------------------------------------------------------

_G.CardsSchema = {
  units = {REPUBLIC = {["CLONE TROOPER INFANTRY"] = {name = "Clone Trooper Infantry", image = "mod-unit"}}},
  upgrades = {["CLONE TROOPER INFANTRY"] = {name = "Clone Trooper Infantry", image = "mod-upgrade"}},
  commands = {},
}
CardsSchemaRevision = 0
dofile("mod/src/includes/LegionHelper.ttslua")

local UNIT_ART = "https://takras.net/legionhelper/unitcards/gar/clone_trooper_front.webp"
local UPGRADE_ART = "https://takras.net/legionhelper/upgradecards/card/clone-trooper-infantry.webp"
feedText = [[{
  "units": {"Republic": {"Corps": [
    {"name": "Clone Trooper Infantry", "image": "]] .. UNIT_ART .. [["}
  ]}},
  "upgrades": {"Personnel": [
    {"name": "Clone Trooper Infantry", "image": "]] .. UPGRADE_ART .. [["}
  ]}
}]]

local failures = 0
local function check(what, ok)
  print((ok and "ok   " or "FAIL ") .. what)
  if not ok then failures = failures + 1 end
end

local function faceOf(guid)
  for _, data in ipairs(spawned) do
    if data.GUID == guid then return data.CustomDeck["1"].FaceURL end
  end
end

-- A unit card, its leader, and an upgrade card of the same name on the table.
objects = {
  card("unit01", "Clone Trooper Infantry", "mod-unit"),
  leader("unit01"),
  card("upgr01", "Clone Trooper Infantry", "mod-upgrade"),
}
loadLegionHelperCards()
check("the unit's card takes the unit's art", faceOf("unit01") == UNIT_ART)
check("the upgrade's card takes the upgrade's art", faceOf("upgr01") == UPGRADE_ART)
check("new cards: the unit's data takes the unit's art",
  _G.CardsSchema.units.REPUBLIC["CLONE TROOPER INFANTRY"].image == UNIT_ART)
check("new cards: the upgrade's data takes the upgrade's art",
  _G.CardsSchema.upgrades["CLONE TROOPER INFANTRY"].image == UPGRADE_ART)

-- A card of that name with no leader naming it is taken for the upgrade.
spawned = {}
objects = {card("lone01", "Clone Trooper Infantry", "mod-upgrade")}
loadLegionHelperCards()
check("a card no leader names takes the upgrade's art", faceOf("lone01") == UPGRADE_ART)

if failures > 0 then
  error(failures .. " failure(s)")
end
print("all passed")
