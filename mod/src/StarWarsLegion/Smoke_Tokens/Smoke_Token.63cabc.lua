rangeKey = "smokeToken"

require('!/TokenWithRangeRuler')

-- ============================ Smoke volume ============================
-- R keeps its vanilla job, the ring on the ground. E, next to it, shows the
-- volume the smoke really occupies: a cylinder covering range 1 from the edge
-- of the token, rising to the notched silhouette height above the token and
-- running down to the table. A perched token therefore gets a taller column:
-- height = 2.707 + (token y - ground y).
--
-- NOTHING IS SCALED. The prefab is built at the rule's exact size (radius
-- 6.37008, height 2.707, base at the origin): the radius comes from the rule,
-- not from the token, and the smoke is made of billboards that a non-uniform
-- scale squashes (a stretched unit volume once smeared them vertically by a
-- factor of 3.4). Height is not scaled either: to reach the table, copies are
-- STACKED.

SMOKE_BUNDLE = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/smoke_volume.unity3d"
SILHOUETTE_NOTCHED = 2.707   -- templateInfo.silhouetteHeight.notched
SMOKE_HEIGHT = 2.707         -- the prefab's height; its radius is the ring the mod already draws
SMOKE_MAX_COPIES = 5         -- each copy costs ~160 particles
RANGE_2 = 12.0               -- 12 inches = 12 TTS units
-- Height comparison tolerance: wide enough for getPosition noise, fine
-- against the 2.707 step.
EPS_Y = 0.02
-- Gap left open between two volumes. Kept volumes never move, so the join
-- with the head rarely lands exactly; filling a small gap would cost a whole
-- copy almost on top of an existing one, and diffuse smoke hides it. 15 % of
-- a step.
GAP_TOLERATED = 0.4

smokeVolumeGUIDs = {}
smokeWanted = false           -- the WANTED state, distinct from what is shown

local baseOnLoad = onLoad

function onLoad(state)
  if baseOnLoad then baseOnLoad(state) end
  smokeVolumeGUIDs = {}
  smokeWanted = false
  createSmokeButton()
  -- Impose, never toggle: an undo replays this load with the snapshot's
  -- state, and a toggle would invert itself on the second pass.
  local wanted, oldVolumes = false, nil
  if state and state ~= "" then
    local ok, t = pcall(function() return JSON.decode(state) end)
    if ok and type(t) == "table" then
      wanted = (t.smoke == true)
      oldVolumes = t.volumes
    end
  end
  sweepOrphanSmoke(oldVolumes)
  smokeWanted = wanted
  if wanted then Wait.frames(function() showSmoke() end, 4) end
end

-- E, twin of the vanilla R button and placed next to it: same size and
-- colours as in TokenWithRangeRuler. One button only, reoriented on flip (see
-- !/RangeRulers): two superposed "E"s would read as an "H". Only the
-- placement angle is given.
SMOKE_BUTTON_ANGLE = 35.0

function createSmokeButton()
  self.createButton({
    click_function = "toggleSmoke",
    function_owner = self,
    label = "E",
    tooltip = "Smoke effect",
    position = ringButtonPosition(SMOKE_BUTTON_ANGLE),
    rotation = uprightButtonRotation(SMOKE_BUTTON_ANGLE),
    scale = { 0.5, 0.5, 0.5 },
    width = 400,
    height = 300,
    font_size = 200,
    color = { 0, 0, 0, 1 },
    font_color = { 0.1212, 0.8127, 0, 1 },
  })
  registerOrientedButton("E", SMOKE_BUTTON_ANGLE)
end

function toggleSmoke()
  smokeWanted = not smokeWanted
  if smokeWanted then showSmoke() else clearSmoke() end
end

-- Capital S: TTS never calls a lowercase onsave.
function onSave()
  -- The wanted state, not the shown one, so a save taken while the token is
  -- held keeps its smoke. The volumes' GUIDs survive the save and must be
  -- destroyed at load, see sweepOrphanSmoke.
  return JSON.encode({ smoke = smokeWanted, volumes = smokeVolumeGUIDs })
end

function onDestroy()
  clearSmoke()
  if clearRangeRuler then clearRangeRuler() end
end

-- TTS shows a placeholder cube while a Custom Assetbundle loads, and neither a
-- tiny spawn scale nor spawnObjectJSON removes it. What works: the volume is
-- born invisible to every colour and reveals itself a moment later. The smoke
-- takes ~2 s to build up anyway, so the delay does not show.
ALL_SEAT_COLOURS = {
  "White", "Brown", "Red", "Orange", "Yellow", "Green",
  "Teal", "Blue", "Purple", "Pink", "Grey", "Black",
}
-- Two delays on purpose: a masked volume keeps emitting, so the later it is
-- revealed the denser it pops in. The long one is only needed cold, when no
-- volume exists and the asset may not be cached. Warm, the cube cannot show,
-- and the new copy should build up in front of the player.
REVEAL_DELAY = 0.4
REVEAL_DELAY_WARM = 0.05

-- A removed volume vanishes at once. Every softer exit was tried in play: a
-- tint fade (the shader ignores tint), sinking it under the table, stopping
-- the emission from Lua with and without a looping effect declared in the
-- bundle. TTS purges the outgoing effect instead of letting it die out.
-- Closed subject.

-- No onPickUp: the smoke follows the token while it is carried. The child
-- keeps its height and tracks x/z only, so the cloud stays on the ground when
-- the token is lifted, and the 2 cm trigger collider baked in the prefab
-- keeps the token from resting on its own volume.

-- The token may land on higher or lower terrain: the ground is measured at
-- drop, once the token is at rest, not every frame. Rebuilding on release
-- would put the volume under a token still falling and bring the float back.
function onDrop(colorName)
  if not smokeWanted then return end
  Wait.condition(
    function() showSmoke() end,
    function() return self.resting end,
    5,
    function() showSmoke() end)   -- never wait for ever
end

-- Ground height under the token: the LOWEST hit, not the first. The first
-- returned the roof of a building the token sat on, and the smoke stopped on
-- the roof instead of running down the walls. The range 2 bound in
-- smokeGeometry keeps a hole in the table from reaching the room's floor.
function groundY()
  local p = self.getPosition()
  local hits = Physics.cast({
    origin = { p.x, p.y - 0.02, p.z },
    direction = { 0, -1, 0 },
    type = 1,
    max_distance = 30,
  })
  local lowest = nil
  for _, h in ipairs(hits or {}) do
    local o = h.hit_object
    if o and o ~= self
       and o.held_by_color == nil
       and o.getName() ~= "Smoke Volume" then
      if lowest == nil or h.point.y < lowest then lowest = h.point.y end
    end
  end
  return lowest or (p.y - 0.4)   -- nothing hit: assume the token sits on the table
end

-- Column geometry at drop time: the base height of the HEAD volume, the only
-- imposed height, and the floor under which stacking is pointless.
function smokeGeometry()
  local b = self.getBounds()
  local tokenTop = b.center.y + b.size.y * 0.5
  local tokenBottom = b.center.y - b.size.y * 0.5
  -- Down to the table, but never more than range 2 below the token's
  -- underside: a token at the edge of a holed board would otherwise fill the
  -- room down to its floor, ~160 particles a copy.
  local floor = math.max(groundY(), tokenBottom - RANGE_2)
  -- Anchored by the TOP, never by the floor: the rule is about the top, which
  -- must sit exactly at token top + 2.707. Stacking from the floor quantised
  -- it to a multiple of the step; anchored by the top, the overflow is at the
  -- bottom, under the table, the one side where it costs nothing.
  return tokenTop + SILHOUETTE_NOTCHED - SMOKE_HEIGHT, floor
end

-- Spawns ONE volume at the given base height. Returns its GUID, or nil.
function spawnSmokeVolume(baseY, revealDelay)
  -- baseY is interpolated into Lua source: an inf or a nan would produce a
  -- script that does not compile, silently. GUIDs are alphanumeric.
  if baseY ~= baseY or baseY == math.huge or baseY == -math.huge then
    print("Smoke token: invalid volume height, copy skipped")
    return nil
  end
  -- The child follows the token itself, as spawnRangeRuler already does: no
  -- Lua timer per token. NOT setPositionSmooth, which wakes physics and
  -- collides; setPosition is a direct placement. anchorY is frozen after the
  -- spawn for every volume but the head, the only one that follows the token
  -- in height; x/z follow for all, so the column slides with the token.
  -- The child also reveals itself: a timer here would be cancelled by the
  -- destroyObject calls the next reshuffle makes.
  local follow =
    "anchor = '" .. self.getGUID() .. "'\n" ..
    "anchorY = " .. tostring(baseY) .. "\n" ..
    "function onLoad()\n" ..
    "  Wait.time(function() self.setInvisibleTo({}) end, " .. tostring(revealDelay) .. ")\n" ..
    "end\n" ..
    "function onFixedUpdate()\n" ..
    "  local t = getObjectFromGUID(anchor)\n" ..
    "  if t == nil then return end\n" ..
    "  local q = t.getPosition()\n" ..
    "  local m = self.getPosition()\n" ..
    "  if math.abs(q.x - m.x) > 0.001 or math.abs(q.z - m.z) > 0.001\n" ..
    "     or math.abs(anchorY - m.y) > 0.001 then\n" ..
    "    self.setPosition({q.x, anchorY, q.z})\n" ..
    "  end\n" ..
    "end"

  local p = self.getPosition()
  local vol = spawnObjectJSON({ json = JSON.encode({
    Name = "Custom_Assetbundle",
    Transform = {
      posX = p.x, posY = baseY, posZ = p.z,
      rotX = 0, rotY = 0, rotZ = 0,
      scaleX = 1, scaleY = 1, scaleZ = 1,
    },
    Nickname = "Smoke Volume",
    Locked = true,
    Grid = false, Snap = false, Autoraise = false, Sticky = false,
    Tooltip = false, GridProjection = false, IgnoreFoW = false,
    DragSelectable = false, MeasureMovement = false, HideWhenFaceDown = false,
    CustomAssetbundle = {
      AssetbundleURL = SMOKE_BUNDLE,
      AssetbundleSecondaryURL = "",
      MaterialIndex = 0,
      TypeIndex = 0,
      LoopingEffectIndex = 0,
    },
    LuaScript = follow,
    LuaScriptState = "",
  }) })
  vol.interactable = false
  vol.setInvisibleTo(ALL_SEAT_COLOURS)
  return vol.getGUID()
end

-- KEPT VOLUMES NEVER MOVE. The column is anchored by its top, so a grid of
-- heights recomputed at every drop slid as a whole whenever the token changed
-- altitude, and every kept volume shifted to rejoin it: unnoticed when
-- instant, a disc of smoke sinking through the table when smoothed. Smoke
-- lying on the ground has no reason to move because the token climbed on a
-- crate. So, top to bottom:
--   1. the HEAD follows the token. It alone changes height, it carries the
--      rule of the top, and it moves with the token, which reads naturally.
--      It is reused only if it is still CLOSE to the new top, otherwise it is
--      left where it is and a new head is made, or smoke that ran down to the
--      ground would climb a whole storey back up.
--   2. every other volume stays exactly where it is; only the useless ones
--      go, above the head or buried under the floor.
--   3. the gaps are filled with NEW volumes, overlapping rather than edge to
--      edge: an overlap is invisible in diffuse smoke, a hole would show.
function showSmoke()
  -- Heights are read ONCE: a dead GUID (volume deleted by hand) is dropped,
  -- the rest is sorted top down.
  local vols = {}
  for _, g in ipairs(smokeVolumeGUIDs) do
    local o = getObjectFromGUID(g)
    if o then table.insert(vols, { g = g, o = o, y = o.getPosition().y }) end
  end
  table.sort(vols, function(a, c) return a.y > c.y end)

  local headY, floor = smokeGeometry()
  local step = SMOKE_HEIGHT
  local reveal = (#vols == 0) and REVEAL_DELAY or REVEAL_DELAY_WARM

  -- 1. The head: the volume CLOSEST to the new top, reused only if the gap
  -- stays small against the step.
  local head, headGap
  for _, v in ipairs(vols) do
    local d = math.abs(v.y - headY)
    if headGap == nil or d < headGap then head, headGap = v, d end
  end
  if head and headGap >= 0.35 * step then head = nil end
  if head then
    head.o.setVar("anchorY", headY)
    head.y = headY
  end

  -- 2. The kept volumes: under the head, and still far enough above the floor
  -- to be worth their particles. The 8 % margin covers the token lying flat,
  -- where its own thickness used to trigger a copy.
  -- destroyObject cancels this script's pending timers, so nothing here may
  -- rely on a timer of ours; the children reveal themselves.
  local kept = {}
  for _, v in ipairs(vols) do
    if v ~= head then
      if v.y < headY - EPS_Y and v.y + step > floor + 0.08 * step then
        table.insert(kept, v)
      else
        destroyObject(v.o)
      end
    end
  end

  -- 3. Fill top down. cursor is the base height of the last volume kept:
  -- everything below it is still to cover.
  local list, cursor = {}, nil
  if head then
    head.o.setInvisibleTo({})
    table.insert(list, head.g)
    cursor = headY
  else
    local g = spawnSmokeVolume(headY, reveal)
    if g then
      table.insert(list, g)
      cursor = headY
    end
  end
  for _, v in ipairs(kept) do
    while cursor ~= nil
      and #list < SMOKE_MAX_COPIES
      and v.y + step < cursor - GAP_TOLERATED do
      local g = spawnSmokeVolume(cursor - step, reveal)
      if g == nil then break end
      table.insert(list, g)
      cursor = cursor - step
    end
    if #list < SMOKE_MAX_COPIES then
      v.o.setInvisibleTo({})
      table.insert(list, v.g)
      cursor = v.y
    else
      destroyObject(v.o)
    end
  end
  while cursor ~= nil
    and #list < SMOKE_MAX_COPIES
    and cursor > floor + 0.08 * step do
    local g = spawnSmokeVolume(cursor - step, reveal)
    if g == nil then break end
    table.insert(list, g)
    cursor = cursor - step
  end

  smokeVolumeGUIDs = list
end

-- Turning the smoke off destroys the volumes, which is what makes turning it
-- back on replay the build-up instead of showing a full cloud at once. Also
-- used at load, to sweep what a save left behind, and when the token goes.
function clearSmoke()
  local list = smokeVolumeGUIDs
  smokeVolumeGUIDs = {}
  for _, g in ipairs(list) do
    local o = getObjectFromGUID(g)
    if o then destroyObject(o) end
  end
end

-- A save keeps the volumes; at load they are destroyed by GUID, or they would
-- pile up from session to session. By GUID and not by scanning every object:
-- a getAllObjects pass per token on a table of thousands was slow, and
-- fragile while the child's script was not loaded yet.
function sweepOrphanSmoke(guids)
  for _, g in ipairs(guids or {}) do
    local o = getObjectFromGUID(g)
    if o and o.getName() == "Smoke Volume" then destroyObject(o) end
  end
end
