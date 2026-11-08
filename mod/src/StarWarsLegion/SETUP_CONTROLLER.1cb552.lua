require('!/Deck')
require('!/Shelf')

function onload(save_state)
    _G.Deck = Deck:create()
    _G.Shelf = Shelf:create()
    self.interactable = false

    -- intialize
    setUpCards = Global.getTable("setUpCards")
    setUpData = Global.getTable("setUpData")
    battlefieldZone = getObjectFromGUID(Global.getVar("battlefieldZoneGUID"))
    gameData = getObjectFromGUID(Global.getVar("gameDataGUID"))
    battlefieldTint = gameData.getTable("battlefieldTint")

    -- token scripts
    _G.scriptRange1Token = nil
    _G.scriptBombCart = nil
    _G.scriptPOIToken = nil
    getTokenScripts()

    -- buttonObjs
    optionObjs = {}
    optionObjs.objective = getObjectFromGUID("9480a7")
    optionObjs.deployment = getObjectFromGUID("538f4d")
    optionObjs.conditions = getObjectFromGUID("c6b3a9")
    -- 2024 missions have two Advantages, one per player. Each player's goes
    -- on the mount nearer their seat: "conditions" is nearer the red seat,
    -- "advantageBlueSeat" nearer the blue seat.
    optionObjs.advantageBlueSeat = getObjectFromGUID("07a89d")

    optionButtons = {}
    optionButtons.objective = getObjectFromGUID("10483c")
    optionButtons.deployment = getObjectFromGUID("1e6398")
    optionButtons.conditions = getObjectFromGUID("337dc3")
    optionButtons.advantageBlueSeat = getObjectFromGUID("5007f8")

    optionZones = {}
    optionZones.objective = getObjectFromGUID("d0ca46")
    optionZones.deployment = getObjectFromGUID("b74727")
    optionZones.conditions = getObjectFromGUID("ec8c41")
    optionZones.advantageBlueSeat = getObjectFromGUID("00f1b3")

    objectiveMenu()
    deploymentMenu()
    conditionsMenu()
    advantageBlueSeatMenu()

    _G.selectedScenario = "standard"
    _G.mirrorDeployment = false
    drawInput()
end

function drawInput()
  self.clearInputs()
  self.createInput({
    input_function = "scenarioChanged",
    function_owner = self,
    label          = "Scenario",
    alignment      = 3,
    position       = {x = -3.0, y = 0.2, z = 0},
    rotation       = {x = 0, y = 180, z = 0},
    width          = 2000,
    height         = 350,
    font_size      = 323,
    validation     = 4,
    value          = scenarioLabel(_G.selectedScenario),
    tooltip        = "Battlefield Deck Type",
  })
end

function scenarioChanged(_, _, input, editing)
  if input and not editing then
    _G.selectedScenario = input
  end
end

function changeScenario(params)
  _G.selectedScenario = params[1]
  drawInput()
end

function getTokenScripts()
  getObjectFromGUID("4d25eb").takeObject({
    callback_function = function(token)
      _G.scriptRange1Token = token.getLuaScript()
      destroyObject(token)
    end
  })
  _G.scriptBombCart = getObjectFromGUID("b497e1").getLuaScript()
  getObjectFromGUID("094230").takeObject({
    callback_function = function(poi)
      _G.scriptPOIToken = poi.getLuaScript()
      destroyObject(poi)
      end
  })
end

function objectiveMenu()
    clearButton("objective")
    createOptionButton("objective", "checkObjective", "Secondary", "Spawn Relevant Secondary Objective Tokens", {0,0.913,1})
end

function deploymentMenu()
    clearDeploymentBoundary()
    clearButton("deployment")
    createOptionButton("deployment", "checkDeployment", "Objective", "Create Deployment overlay and spawn Objective map and tokens", {0,0.913,1})
end


function conditionsMenu()
    clearButton("conditions")
    createOptionButton("conditions", "checkConditions", "Red Seat Advantage", "Spawn Relevant Advantage Tokens for the player at the red seat", {0,0.913,1})
end

function advantageBlueSeatMenu()
    clearButton("advantageBlueSeat")
    createOptionButton("advantageBlueSeat", "checkAdvantageBlueSeat", "Blue Seat Advantage", "Spawn Relevant Advantage Tokens for the player at the blue seat", {0,0.913,1})
end

function checkAdvantageBlueSeat()
  local card = getObjectFromZone("advantageBlueSeat")
  if not card then
    clearButton("advantageBlueSeat")
    createOptionButton("advantageBlueSeat", "checkAdvantageBlueSeat", "Mount Advantage", "No Advantage selected, mount the blue seat's advantage card below", {0.7,0,0})
    resetTimer("advantageBlueSeat")
    return
  end
  local name = card.getName()
  if Deck:getBattleCardType(name, _G.selectedScenario) ~= "condition" then
    clearButton("advantageBlueSeat")
    createOptionButton("advantageBlueSeat", "checkAdvantageBlueSeat", "Wrong Card", "Wrong Card mounted, mount the blue seat's advantage card below", {0.7,0,0})
    resetTimer("advantageBlueSeat")
    return
  end
  spawnObjs("advantageBlueSeat", name)
  advantageBlueSeatMenu()
end

function checkCardCall(cardTable)
  if cardTable[1] == "advantageBlueSeat" then
    return checkAdvantageBlueSeat()
  end
  return checkCard(cardTable[1])
end

function checkCard(cardType)
  local battleDeckScenario = _G.selectedScenario
  setUpCardData = nil
  zoneObj = nil
  zoneObj = getObjectFromZone(cardType)

  if zoneObj then
    local name = zoneObj.getName()
    local type = Deck:getBattleCardType(name, battleDeckScenario)
    -- TODO: Clean up once there is a better mechanism for these types of cards.
    if not type then
      return false
    end
    if type == "condition" then
      type = "conditions"
    end
    if type:upper() == cardType:upper() then
      self.call("activate"..type, name)
    else
      self.call("wrong".. type)
    end
  else
    self.call("no".. cardType)
  end
  return true
end

function getObjectFromZone(selectedZone)
    local zoneObjs = nil
    local selectedObj =  nil
    local zoneObjs = optionZones[selectedZone].getObjects()
    for i, obj in pairs(zoneObjs) do
        if obj ~= optionObjs[selectedZone] then
            selectedObj = obj
            break
        end
    end
    if selectedObj ~= nil then
        return selectedObj
    else
        return nil
    end
end


-- Called by the game controller before setting up a mission: when the red
-- seat is the blue player, the deployment zones are mirrored so each
-- player's zone is on their own side of the table.
function setMirrorDeployment(params)
  _G.mirrorDeployment = params.mirror == true
end

-- Called by the game controller before setting up a mission: the Objective's
-- POIs then go on the battlefield instead of staying in its bag.
function setPlaceMissionPois(params)
  _G.missionPoisOnMap = params.place == true
end

-- A POI is put exactly on its spot, flat, and locked at once: letting it fall
-- could clip an arch beside it and knock it away. It goes on the ground when
-- nothing stands there, even under an arch, and on top of a hill or a building
-- when one does. Players can unlock one with the usual L key to adjust it.
local POI_ORIGIN_HEIGHT = 0.08 -- the token's origin is on its top face
local POI_CLEARANCE_CENTER = 0.6
local POI_CLEARANCE_SIZE = {1.6, 0.9, 1.6} -- under the POI's 2": grazing a wall is fine
local POI_CAST_HEIGHT = 30
local MISSION_POI_TAG = "MissionPOI"
-- A mound's collider can sit well below what is drawn, which would sink the
-- POI into it, so low terrain counts by its visible top. Not taller terrain:
-- the visible top of a wood is its treetops, its collider the ground to stand on.
local POI_LOW_TERRAIN = 1

function isReconSelected()
  return Deck:_scenarioKey(_G.selectedScenario) == "skirmish"
end

local function terrainOnSpot(p)
  local hits = Physics.cast({
    origin       = {p.x, p.y + POI_CLEARANCE_CENTER, p.z},
    direction    = {0, 1, 0},
    type         = 3,
    size         = POI_CLEARANCE_SIZE,
    max_distance = 0,
  })
  local terrain = {}
  for _, hit in ipairs(hits or {}) do
    local obj = hit.hit_object
    if obj ~= nil and obj.getName() ~= "POI Token" and obj.getName() ~= "BATTLEFIELD" then
      terrain[obj.getGUID()] = true
    end
  end
  return terrain
end

-- A POI only rests on terrain that carries most of it, as a real token
-- would: the height is read under 5 points (its centre and 4 towards its
-- edges), and the terrain counts only when it is under at least 3 of them. A
-- thin tree trunk beside the spot, under one point or none, leaves the POI on
-- the ground; a cliff or a roof under it holds it.
local POI_SAMPLE_OFFSET = 0.6
local POI_SAMPLES = {{0, 0}, {POI_SAMPLE_OFFSET, 0}, {-POI_SAMPLE_OFFSET, 0}, {0, POI_SAMPLE_OFFSET}, {0, -POI_SAMPLE_OFFSET}}
local POI_SAMPLES_NEEDED = 3

-- The top of what stands on the spot, from a surface at height `base`.
local function topOfTerrain(p, base)
  local terrain = terrainOnSpot({x = p.x, y = base, z = p.z})
  if next(terrain) == nil then
    return base
  end
  local height, carried = base, 0
  for _, offset in ipairs(POI_SAMPLES) do
    local top = nil
    local hits = Physics.cast({
      origin       = {p.x + offset[1], base + POI_CAST_HEIGHT, p.z + offset[2]},
      direction    = {0, -1, 0},
      type         = 1,
      max_distance = POI_CAST_HEIGHT + 1,
    })
    for _, hit in ipairs(hits or {}) do
      local obj = hit.hit_object
      if obj ~= nil and terrain[obj.getGUID()] and hit.point.y > base + 0.01 then
        local surface = hit.point.y
        local visual = obj.getVisualBoundsNormalized()
        local visualTop = visual.center.y + visual.size.y / 2
        if visualTop - base <= POI_LOW_TERRAIN then
          surface = math.max(surface, visualTop)
        end
        top = math.max(top or surface, surface)
      end
    end
    if top then
      carried = carried + 1
      height = math.max(height, top)
    end
  end
  if carried < POI_SAMPLES_NEEDED then
    return base
  end
  return height
end

-- The height of the surface a POI rests on. Terrain can be stacked (a crate
-- on a platform): once on top of one piece, look again from there, until
-- nothing stands on the spot any more. An arch high above stays ignored, as
-- on the ground.
local POI_MAX_LEVELS = 5
local function poiRestHeight(p)
  local height = p.y
  for _ = 1, POI_MAX_LEVELS do
    local top = topOfTerrain(p, height)
    if top <= height + 0.01 then
      break
    end
    height = top
  end
  return height
end

local function poisInBag(bag)
  local pois = {}
  for _, entry in ipairs(bag.getObjects()) do
    if entry.name == "POI Token" then
      table.insert(pois, entry)
    end
  end
  return pois
end

local function placeMissionPois(bag, cardName)
  local positions = Global.call("getMissionPoiPositions", {
    cardName = cardName,
    isRecon  = isReconSelected(),
  })
  if positions == nil then
    broadcastToAll("The map doesn't match this mission: the POIs stay in the Objective's bag.", {1, 0.8, 0.4})
    return
  end
  -- A mission built again must not leave the last one's POIs on the map.
  for _, poi in ipairs(getObjectsWithTag(MISSION_POI_TAG)) do
    destroyObject(poi)
  end
  Wait.condition(function()
    for i, entry in ipairs(poisInBag(bag)) do
      local p = positions[i]
      if p ~= nil then
        local target = {p.x, poiRestHeight(p) + POI_ORIGIN_HEIGHT, p.z}
        bag.takeObject({
          guid              = entry.guid,
          position          = target,
          rotation          = {0, 0, 0},
          smooth            = false,
          callback_function = function(poi)
            poi.addTag(MISSION_POI_TAG)
            poi.setLock(true)
            poi.setPosition(target)
            poi.setRotation({0, 0, 0})
          end,
        })
      end
    end
  end, function()
    return #poisInBag(bag) >= #positions
  end, 10, function()
    broadcastToAll("The POIs took too long to load: they stay in the Objective's bag.", {1, 0.8, 0.4})
  end)
end

-- Removes battle cards from the setup mounts (before the game controller
-- places a new mission).
function clearMountedCards()
  for _, zone in pairs(optionZones) do
    for _, obj in ipairs(zone.getObjects()) do
      local type = obj.type or obj.tag
      if type == "Card" or type == "Deck" then
        destroyObject(obj)
      end
    end
  end
end

-- cardType is a card data key, or "advantageBlueSeat" for the Advantage on
-- the mount nearer the blue seat (a "condition" card beside its own mount).
function spawnObjs(cardType, selectedBattleCardName, callback)
  local dataType = cardType == "advantageBlueSeat" and "condition" or cardType
  local objects = Deck:getBattleCardObjects(
    selectedBattleCardName,
    dataType,
    _G.selectedScenario
  )
  if #objects == 0 then
    return
  end
  -- Beside each card's mount.
  local position = ({
    advantageblueseat = {49, 1, 20},
    deployment   = {49, 1, 16},
    objective    = {49, 1, 12},
    condition    = {49, 1, 08},
  })[cardType:lower()]
  Shelf:spawnAdditionalObjects({
    name     = selectedBattleCardName .. "'s Objects",
    position = position,
    objects  = objects,
    callback = callback,
    -- TODO: Make this global somehow instead.
    scripts  = {
      ["toggle-range-1"] = _G.scriptRange1Token,
      ["bomb-cart"]      = _G.scriptBombCart,
      ["poi-token"]      = _G.scriptPOIToken
    }
  })
end

local xStart = -25
local zStart = 15
local yValue = 20

local deployLinks = {}
  deployLinks.r = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_metal_v2.unity3d"
  deployLinks.rh = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_half_metal_v2.unity3d"
  deployLinks.rs = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_half_metal_v2.unity3d"
  deployLinks.rss = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_half_metal_v2.unity3d"
  deployLinks.rl = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_l_metal_v2.unity3d"
  deployLinks.rc = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_corner_metal_v2.unity3d"
  deployLinks.rcc = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_red_spawn_corner_metal_v2.unity3d"
  deployLinks.b = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_metal_v2.unity3d"
  deployLinks.bh = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_half_metal_v2.unity3d"
  deployLinks.bs = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_half_metal_v2.unity3d"
  deployLinks.bss = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_half_metal_v2.unity3d"
  deployLinks.bl = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_l_metal_v2.unity3d"
  deployLinks.bc = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_corner_metal_v2.unity3d"
  deployLinks.bcc = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_blue_spawn_corner_metal_v2.unity3d"

local deployRotations = {}
  deployRotations.r = 0 
  deployRotations.rh = 0
  deployRotations.rs = 90
  deployRotations.rss = 90
  deployRotations.rl = 0
  deployRotations.rc = 0
  deployRotations.rcc = 0
  deployRotations.b = 0
  deployRotations.bh = 0
  deployRotations.bs = 90
  deployRotations.bss = 90
  deployRotations.bl = 0
  deployRotations.bc = 0
  deployRotations.bcc = 0

local deployOffset = {}
  deployOffset.r = {0, 0, 0}
  deployOffset.rh = {0, 0, -1.5}
  deployOffset.rs = {1.5, 0, 0}
  deployOffset.rss = {-1.5, 0, 0}
  deployOffset.rl = {0, 0, 0}
  deployOffset.rc = {1.5, 0, -1.5}
  deployOffset.rcc = {-1.5, 0, -1.5}
  deployOffset.b = {0, 0, 0}
  deployOffset.bh = {0, 0, 1.5}
  deployOffset.bs = {-1.5, 0, 0}
  deployOffset.bss = {1.5, 0, 0}
  deployOffset.bl = {0, 0, 0}
  deployOffset.bc = {-1.5, 0, 1.5}
  deployOffset.bcc = {1.5, 0, 1.5}

function AddVectors(vectorA, vectorB)
  vectorA[1] = vectorA[1] + vectorB[1]
  vectorA[2] = vectorA[2] + vectorB[2]
  vectorA[3] = vectorA[3] + vectorB[3]
  return vectorA  
end

function spawnBoundaryCell(cell, x, z)
  local asset = deployLinks[cell]
  local offset = deployOffset[cell]
  local pos = {
    xStart + (6 * (x - 1)),
    yValue,
    zStart - (6 * (z - 1)),
  }

  pos = AddVectors(pos, offset)

  local projector = spawnObject({
    type        = "Custom_AssetBundle",
    position    = pos,
    scale       = {0, 0, 0},
    rotation    = {0, deployRotations[cell], 0}
  })
  projector.setName("Deployment Boundary")
  projector.setLock(true)
  projector.setCustomObject({
    assetbundle = asset,
  })
end

function spawnDeploymentBoundary(matrix, mirror)
    local function invertMatrix(input)
      -- See https://github.com/swlegion/tts/issues/275.
      local output = {}
      local height = #input
      local width  = #input[1]
      for y = 1, height, 1 do
        output[y] = {}
        for x = 1, width, 1 do
          output[y][x] = " "
        end
      end
      for y = 1, height, 1 do
        for x = 1, width, 1 do
          output[y][x] = input[height + 1 - y][width + 1 - x]
        end
      end
      return output
    end
    
    -- Swaps red and blue cells ("rh" <-> "bh"). Each red cell's art and offset
    -- is its blue counterpart turned 180 degrees, so skipping invertMatrix and
    -- swapping colors draws each player's zone on the opposite edge.
    local function swapColors(input)
      local output = {}
      for y, row in ipairs(input) do
        output[y] = {}
        for x, cell in ipairs(row) do
          local first = cell:sub(1, 1)
          if first == "r" then
            cell = "b" .. cell:sub(2)
          elseif first == "b" then
            cell = "r" .. cell:sub(2)
          end
          output[y][x] = cell
        end
      end
      return output
    end

    if mirror then
      matrix = swapColors(matrix)
    else
      matrix = invertMatrix(matrix)
    end
    -- matrix is in the format of
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- { x, x, x, x, x, x, x, x, x, x, x, x }
    -- ... where "x" can either be:
    -- "r*" :  red deployment zone (the suffix picks the edge piece)
    -- "b*" :  blue deployment zone
    -- ""  :  ignore
    for z, row in pairs(matrix) do
      for x, cell in pairs(row) do
        if cell == " " then
          -- skip the blank cells
        elseif cell == "bl" then
          spawnBoundaryCell("bs", x, z)
          spawnBoundaryCell("bcc", x, z)
        elseif cell == "rl" then
          spawnBoundaryCell("rs", x, z)
          spawnBoundaryCell("rcc", x, z)
        else
          spawnBoundaryCell(cell, x, z)
        end
      end
    end
end

function clearDeploymentBoundary()
    local battlefieldObjs = battlefieldZone.getObjects()
    for _, obj in pairs(battlefieldObjs) do
        if obj.getName() == "Deployment Boundary" then
            destroyObject(obj)
        end
    end
end

function activateobjective(name)
  spawnObjs("objective", name)
  objectiveMenu()
end

function resetTimer(setUpType)
    Timer.destroy(setUpType.."ResetTimer")
    Timer.create({
        identifier     = setUpType.."ResetTimer",
        function_name  = setUpType.."Menu",
        function_owner = self,
        delay          = 4,
        repetitions    = 1
    })
end

function noObjectiveTokensMenu()
    clearButton("objective")
    createOptionButton("objective", "checkObjective", "No Tokens", "No relevant Secondary Objective tokens needed", {0.7,0,0})
    resetTimer("objective")
end

function noConditionsTokensMenu()
    clearButton("conditions")
    createOptionButton("conditions", "checkConditions", "No Tokens", "No relevant Advantage tokens needed", {0.7,0,0})
    resetTimer("conditions")
end

function noDeploymentTokensMenu()
    clearButton("deployment")
    createOptionButton("deployment", "checkDeployment", "No Tokens", "No relevant Objective tokens needed", {0.7,0,0})
    resetTimer("objective")
end

function noDeploymentMenu()
    clearButton("deployment")
    createOptionButton("deployment", "checkDeployment", "No Tokens", "No relevant Objective tokens needed", {0.7,0,0})
    resetTimer("deployment")
end

function activatedeployment(name)
    clearDeploymentBoundary()
    local zone = Deck:getDeploymentBoundary(name, _G.selectedScenario)
    if zone and #zone > 0 then
      spawnDeploymentBoundary(zone, _G.mirrorDeployment)
    end
    Global.call("setPoiPlacementAids", {
      show    = true,
      isRecon = isReconSelected(),
    })
    deactivateDeploymentMenu()
    local callback = nil
    if _G.missionPoisOnMap then
      _G.missionPoisOnMap = false
      callback = function(bag) placeMissionPois(bag, name) end
    end
    spawnObjs("deployment", name, callback)
end

function removeDeploymentOverlay()
    Global.call("setPoiPlacementAids", {show = false})
    deploymentMenu()
end

function deactivateDeploymentMenu()
    clearButton("deployment")
    createOptionButton("deployment", "removeDeploymentOverlay", "Remove Overlay", "Remove Deployment Overlay", {0.7,0,0})
end

function activateconditions(name)
  spawnObjs("condition", name)
  objectiveMenu()
end

function checkObjective()
    checkCard("objective")
end
function checkDeployment()
    checkCard("deployment")
end
function checkConditions()
    checkCard("conditions")
end

function noobjective()
    clearButton("objective")
    createOptionButton("objective", "checkObjective", "Mount Secondary", "No Secondary Objective selected, mount secondary objective card below", {0.7,0,0})
    resetTimer("objective")
end

function wrongobjective()
    clearButton("objective")
    createOptionButton("objective", "checkObjective", "Wrong Card", "Wrong Card mounted, mount secondary objective card below", {0.7,0,0})
    resetTimer("objective")
end

function nodeployment()
    clearButton("deployment")
    createOptionButton("deployment", "checkDeployment", "Mount Objective", "No Objective selected, mount objective card below", {0.7,0,0})
    resetTimer("deployment")
end

function wrongdeployment()
    clearButton("deployment")
    createOptionButton("deployment", "checkDeployment", "Wrong Card", "Wrong Card mounted, mount objective card below", {0.7,0,0})
    resetTimer("deployment")
end

function noconditions()
    clearButton("conditions")
    createOptionButton("conditions", "checkConditions", "Mount Advantage", "No Advantage selected, mount advantage card below", {0.7,0,0})
    resetTimer("conditions")
end

function wrongconditions()
    clearButton("conditions")
    createOptionButton("conditions", "checkConditions", "Wrong Card", "Wrong Card mounted, mount advantage card below", {0.7,0,0})
    resetTimer("conditions")
end


function clearButton(optionSelection)

    optionObjs[optionSelection].clearButtons()

    optionButtons[optionSelection].clearButtons()
    optionButtons[optionSelection].setColorTint({0,0,0})
end

function createOptionButton(optionType, optionClickFunction, optionLabel, optionToolTip, tint)
    optionObj = optionObjs[optionType]
    optionButton = optionButtons[optionType]

    _G["setupControllerOptionFunction"..optionType] = function()
        optionButtons[optionType].AssetBundle.playTriggerEffect(0)
        _G[optionClickFunction]()
    end
    optionObj.createButton({
        click_function = "setupControllerOptionFunction"..optionType, function_owner = self, label = optionLabel, position = {-0.5, 0.3, -1.95}, scale = {0.5, 0.5, 0.5}, width = 2500, height = 600, font_size = #optionLabel > 16 and 240 or 300, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100},tooltip = optionToolTip
    })

    optionButton.createButton({
        click_function = "setupControllerOptionFunction"..optionType, function_owner = self, label = "", position = {0, 0.65, 0}, width = 1400, height = 1400, font_size = 1100, color = {1,1,1,0.01},font_color = {1,1,1,100}, tooltip = optionToolTip, alignment = 3
    })

    optionButton.setColorTint(tint)
end
