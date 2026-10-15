require('!/Analytics')
require('!/Deck')
require('!/Mission')
require('!/common/Zonex')

function onload(save_state)
    _G.Deck = Deck:create()

    -- init values
    gameData = getObjectFromGUID(Global.getVar("gameDataGUID"))
    battlefieldTint = gameData.getTable("battlefieldTint")

    gameController = Global.getTable("gameController")
    mountZone = getObjectFromGUID(gameController.mountZoneGUID)
    battlefieldZone = getObjectFromGUID(Global.getVar("battlefieldZoneGUID"))
    battlefieldTable = getObjectFromGUID(Global.getVar("battlefieldTable"))
    customMapsCartridge = getObjectFromGUID(gameController.customMapsGUID)
    deploymentOverlays = getObjectFromGUID(gameController.deploymentOverlaysGUID)

    listBuilder = Global.getTable("listBuilder")
    redZone = getObjectFromGUID(listBuilder.redZoneGUID)
    blueZone = getObjectFromGUID(listBuilder.blueZoneGUID)
    screen = getObjectFromGUID(Global.getVar("screenGUID"))
    setUpData = Global.getTable("setUpData")
    setUpData.deploymentMount = getObjectFromGUID(setUpData.deploymentMountGUID)
    setUpData.conditionsMount = getObjectFromGUID(setUpData.conditionsMountGUID)
    setUpData.advantageBlueSeatMount = getObjectFromGUID(setUpData.advantageBlueSeatMountGUID)
    setUpData.objectiveMount = getObjectFromGUID(setUpData.objectiveMountGUID)
    commandTokenTrayData = Global.getTable("commandTokenTrayData")
    commandTokenData = Global.getTable("commandTokenData")
    zonesGUIDs = Global.getTable("zonesGUIDs")

    setUpController = getObjectFromGUID(Global.getVar("setUpControllerGUID"))

    blueDeckMount = getObjectFromGUID(listBuilder.blueDeckMountGUID)
    redDeckMount = getObjectFromGUID(listBuilder.redDeckMountGUID)
    blueDeckZone = getObjectFromGUID(listBuilder.blueDeckZoneGUID)
    redDeckZone = getObjectFromGUID(listBuilder.redDeckZoneGUID)

    -- button Models
    dataDiskMount = getObjectFromGUID("a44dcb")

    optionObjs = {}

    optionObjs.gameControllerOption1 = getObjectFromGUID("9200f4")
    optionObjs.gameControllerOption2 = getObjectFromGUID("de5eb8")
    optionObjs.gameControllerOption3 = getObjectFromGUID("44c5b4")
    optionObjs.gameControllerOption4 = getObjectFromGUID("a4448e")
    optionObjs.gameControllerOption5 = getObjectFromGUID("971605")

    optionButtons = {}

    optionButtons.gameControllerOption1Button = getObjectFromGUID("4663eb")
    optionButtons.gameControllerOption2Button = getObjectFromGUID("3c301d")
    optionButtons.gameControllerOption3Button = getObjectFromGUID("05d327")
    optionButtons.gameControllerOption4Button = getObjectFromGUID("6cfaf1")
    optionButtons.gameControllerOption5Button = getObjectFromGUID("3cd1bf")

    backButton = getObjectFromGUID("ae44c9")
    prevButton = getObjectFromGUID("f563ce")
    nextButton = getObjectFromGUID("d81a06")

    homeScreen()
    mainMenu()
end

function homeScreen()
    screen.createButton({click_function = "dud", function_owner = self, label = "", position = {0.9, 0.25, 0}, rotation = {0, -90, 90}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 100, font_color = {0.8867, 0.7804, 0, 1}, alignment = 1})
    printToScreen("STAR WARS LEGION TTS MOD\n by SWL Dev Foundation\n\nSelect an option below to start", 80, 3)
end

-- MENU

function mainMenu()
    timerScreen = false

    printToScreen("STAR WARS LEGION TTS MOD\n by SWL Dev Foundation\n\nSelect an option below to start", 80, 3)

    clearAllButtons()
    local menuEntries = {}
    menuEntries[1] = {functionName = "mapMenu", label = "Maps", tooltip = "Map Menu", buttonTint = {0,0.913,1}}
    menuEntries[2] = {functionName = "gameOptionsMenu", label = "Set Up", tooltip = "Set Up options menu", buttonTint = {0,0.913,1}}
    menuEntries[3] = {functionName = "configMenu", label = "Config", tooltip = "Config Menu", buttonTint = {0,0.913,1}}

    createMenu(menuEntries, 1)

end

function enterTintData(obj, dataString, tintTable)
    local tintString =  "{r = "..tintTable.r..", g = "..tintTable.g..", b = "..tintTable.b.."}"
    enterData(obj, dataString, tintString)
    obj.setTable(dataString, tintTable)
end

function enterData(obj, dataString, newValue)
    dataScript = obj.getLuaScript()
    dataString = dataString .. " = "
    local stringStart = 0
    local valueStart = 0
    stringStart, valueStart = string.find(dataScript, dataString)
    valueStart = valueStart

    local valueEnd = 0
    local valueNil = 0
    valueEnd, valueNil = string.find(dataScript, "\n", valueStart)
    valueEnd = valueEnd

    local newDataScript = string.sub(dataScript, 1, valueStart).. newValue .. string.sub(dataScript, valueEnd)

    obj.setLuaScript(newDataScript)
end

function reset()
    clearMissionCards()
    mission = nil
    mainMenu()
end

function debug()
    local battlefieldObjs = battlefieldZone.getObjects()
    local redObjs = redZone.getObjects()
    local blueObjs = blueZone.getObjects()
    removeLockedRulers()
    reloadObj(battlefieldObjs)
    reloadObj(redObjs)
    reloadObj(blueObjs)
end

function reloadObj(selectedObjs)
    for _, obj in pairs(selectedObjs) do
        if obj.getName() == "Movement Template" then
            destroyObject(obj)
        else
            obj.reload()
        end

    end
end

function removeLockedRulers()
    local allObjs = getAllObjects()
    for _, obj in pairs(allObjs) do
        if obj.getName() == "Cohesion Ruler" or obj.getName() == "Range Ruler" then
            destroyObject(obj)
        end
    end
end

function standbyTokens()
    local allObjs = getAllObjects()
    for i, obj in pairs(allObjs) do
        if obj.getVar("isAToken") == true then
            obj.call("standby")
        end
    end
end

function clearPlayerZones()
    local redZoneObjs = redZone.getObjects()
    local blueZoneObjs = blueZone.getObjects()

    for i, obj in pairs(redZoneObjs) do
        if obj ~= battlefieldTable then
            destroyObject(obj)
        end
    end
    for i, obj in pairs(blueZoneObjs) do
        if obj ~= battlefieldTable then
            destroyObject(obj)
        end
    end
end

function gameOptionsMenu()
    ga_view("game_controller/game_options")
    clearAllButtons()
    changeBackButton("mainMenu", "Go back to Main Menu")
    local menuEntries = {}
    menuEntries[1] = {
      functionName = "flipMap",
      label = "Flip Map",
      tooltip = "Flip the map to the other side",
      buttonTint = {0,0.913,1}
    }
    menuEntries[2] = {
      functionName = "buildMissionMenu",
      label = "Build Mission",
      tooltip = "Build the mission from both players' battle decks (2024 rules)",
      buttonTint = {0,0.913,1}
    }
    menuEntries[3] = {
      functionName = "debug",
      label = "Debug Objects",
      tooltip = "Corrects terrain that is spawned incorrectly or removes stuck rulers or movement templates",
      buttonTint = {0,0.913,1}
    }
    menuEntries[4] = {
      functionName = "spawnCardDecks",
      label = "Spawn Card Decks",
      tooltip = "Spawn Unit/Upgrade/Command cards for manual use",
      buttonTint = {0,0.913,1}
    }
    menuEntries[5] = {
      functionName = "enableExperimentalFeatures",
      label = "Enable Experiments",
      tooltip = "Enables experimental unsupported features",
      buttonTint = {0,0.913,1}
    }
    createMenu(menuEntries, 1)
end

function configMenu()
    ga_view("game_controller/config_menu")
    printToScreen("CONFIG MENU", 80, 3)
    clearAllButtons()
    changeBackButton("mainMenu", "Go back to Main Menu")
    local menuEntries = {}
    menuEntries[1] = {functionName = "cardArtMenu", label = "Card Art", tooltip = "Card art loading options", buttonTint = {0,0.913,1}}
    createMenu(menuEntries, 1)
end

-- Card art from Legion Helper, by takras (see !/LegionHelper): only the art
-- of the cards the mod knows changes, for this session.
function cardArtMenu()
    ga_view("game_controller/config_menu/card_art")
    printToScreen("CARD ART\n\nArt by Legion Helper (legion.takras.net).\nOnly the art changes, for this session.", 80, 3)
    clearAllButtons()
    changeBackButton("configMenu", "Go back to Config Menu")
    local menuEntries = {}
    menuEntries[1] = {functionName = "loadCardArtActive", label = "Load Active", tooltip = "Art for the cards and units on the table only - quick", buttonTint = {0,0.913,1}}
    menuEntries[2] = {functionName = "loadCardArtUpgrades", label = "All Upgrades", tooltip = "Art for every upgrade card", buttonTint = {0,0.913,1}}
    menuEntries[3] = {functionName = "loadCardArtAll", label = "All Cards", tooltip = "Art for every unit, upgrade and command card", buttonTint = {0,0.913,1}}
    createMenu(menuEntries, 1)
end

function loadCardArtActive()
    ga_event("Game", "loadLegionHelperActiveArmy")
    Global.call("loadLegionHelperActiveArmy")
end

function loadCardArtUpgrades()
    ga_event("Game", "loadLegionHelperUpgrades")
    Global.call("loadLegionHelperUpgrades")
end

function loadCardArtAll()
    ga_event("Game", "loadLegionHelperCards")
    Global.call("loadLegionHelperCards")
end

function mapMenu()
    ga_view("game_controller/map_menu")
    printToScreen("MAP MENU", 80, 3)

    clearAllButtons()
    changeBackButton("mainMenu", "Go back to Main Menu")

    callBackMapMenu = "mapMenu"

    local menuEntries = {}
    menuEntries[1] = {functionName = "featuredMapsMenu", label = "Featured Maps", tooltip = "List and download pre-made maps", buttonTint = {0,0.913,1}}
    menuEntries[2] = {functionName = "loadMap", label = "Load Map", tooltip = "Load Map from Data Cartridge", buttonTint = {0,0.913,1}}
    menuEntries[3] = {functionName = "saveMap", label = "Save Map", tooltip = "Save Map to a Data Cartridge", buttonTint = {0,0.913,1}}
    menuEntries[4] = {functionName = "flipMap", label = "Flip Map", tooltip = "Flip the map to the other side", buttonTint = {0,0.913,1}}
    menuEntries[5] = {functionName = "customMapMenu", label = "Custom Maps", tooltip = "Create a Custom Map", buttonTint = {0,0.913,1}}
    menuEntries[6] = {functionName = "clearZones", label = "Clear Map", tooltip = "Clears everything from current Battlefield area", buttonTint = {0,0.913,1}}
    menuEntries[7] = {functionName = "saveConditions", label = "Save Battlefield Tokens", tooltip = "Saves Objects from the Objective/Deployment/Conditions", buttonTint = {0,0.913,1}}
    menuEntries[8] = {functionName = "toggleMaskMid", label = "Toggle Masks : Mid", tooltip = "Toggles Masking Objects for the middle of the Battlefield", buttonTint = {0,0.913,1}}
    menuEntries[9] = {functionName = "togglePoiGuide", label = "Toggle Poi Guide", tooltip = "Toggles Poi Layout Projector to help with Map Creation", buttonTint = {0,0.913,1}}
    menuEntries[10] = {functionName = "togglePoiSnap", label = "Toggle POI Snap", tooltip = "Toggles snap points on the POI guide circles for POI tokens", buttonTint = {0,0.913,1}}
    createMenu(menuEntries, 1)
end

function togglePoiSnap()
    ga_event("Game", "togglePoiSnap")
    Global.call("togglePoiSnapPoints")
end

function featuredMapsMenu()
  ga_view("game_controller/featured_maps")
  printToScreen("FEATURED MAPS\n\nThese are maps featured by the community.\n\nSee https://go.swlegion.dev/maps for details.", 80, 3)
  changeBackButton("mapMenu", "Go back to Maps Menu")
  local buttonTint = {0,0.913,1}
  local menuEntries = {
    {
      label = "Competitive",
      tooltip = "View Competitive Maps",
      functionName = "featuredCompetitiveMenu",
      buttonTint = buttonTint,
    },
    {
      -- Skirmish is called Recon since the rules update; the data files and
      -- the swlegion.dev links still use the old name.
      label = "Recon",
      tooltip = "View Recon (3x3) Maps",
      functionName = "featuredSkirmisMenu",
      buttonTint = buttonTint,
    }
  }
  createMenu(menuEntries, 1)
end

-- WebRequest responses aren't guaranteed to be valid JSON (a dead/expired
-- link can return an HTML error page instead), so JSON.decode needs a pcall
-- guard wherever we feed it a network response - otherwise a single broken
-- community-contributed link crashes with a raw Lua error and leaves the
-- player stuck mid-menu instead of getting a clear message back.
function safeJsonDecode(text)
  local ok, result = pcall(JSON.decode, text)
  if ok and type(result) == "table" then
    return result
  end
  return nil
end

function featuredCompetitiveMenu()
  ga_view("game_controller/featured_maps/competitive")
  printToScreen("FEATURED MAPS\n\nThese are maps featured by the community.\n\nSee https://go.swlegion.dev/maps for details.", 80, 3)
  changeBackButton("featuredMapsMenu", "Go back to featured maps")
  local url = "https://raw.githubusercontent.com/swlegion/tts/master/contrib/maps/competitive.json"
  WebRequest.get(url, function(data)
    local items = safeJsonDecode(data.text)
    if items == nil then
      printToAll("Could not load the featured maps list. Check your connection, or try again later.", {1, 0.5, 0.5})
      featuredMapsMenu()
      return
    end
    local menu = {}
    for _, entry in pairs(items) do
      table.insert(menu, {
        label = entry['name'],
        tooltip = 'Download map',
        url = entry['url'],
        buttonTint = {0,0.913,1}
      })
    end
    createMenu(menu, 1)
  end)
end

function featuredSkirmisMenu()
  ga_view("game_controller/featured_maps/skirmish")
  printToScreen("FEATURED MAPS\n\nThese are maps featured by the community.\n\nSee https://go.swlegion.dev/maps for details.\n\nFull support for Recon is currently limited:\nhttps://go.swlegion.dev/skirmish.", 80, 3)
  changeBackButton("featuredMapsMenu", "Go back to featured maps")
  local url = "https://raw.githubusercontent.com/swlegion/tts/master/contrib/maps/skirmish.json"
  WebRequest.get(url, function(data)
    local items = safeJsonDecode(data.text)
    if items == nil then
      printToAll("Could not load the featured maps list. Check your connection, or try again later.", {1, 0.5, 0.5})
      featuredMapsMenu()
      return
    end
    local menu = {}
    for _, entry in pairs(items) do
      table.insert(menu, {
        label = entry['name'],
        tooltip = 'Download map',
        url = entry['url'],
        buttonTint = {0,0.913,1}
      })
    end
    createMenu(menu, 1)
  end)
end

function createMapMenu(selectedCartridge, mapMenuCallback)
  local selectedMapsTable = selectedCartridge.getObjects()
  local menuEntries = {}
  for iM, entry in pairs(selectedMapsTable) do
      _G["spawnCustomMap"..entry.name] = function() spawnCustomMap(entry.name, selectedCartridge, mapMenuCallback) end
      table.insert(menuEntries, {functionName = "spawnCustomMap"..entry.name, label = entry.name, tooltip = "Load ".. entry.name .." map", buttonTint = {0,0.913,1}})
  end
  createMenu(menuEntries, 1)
end

function customMapMenu()
  ga_view("game_controller/custom_maps")
  clearAllButtons()
  changeBackButton("mapMenu", "Go back to Maps Menu")
  createMapMenu(customMapsCartridge, "mapMenu")
end

-- SETUP Menu

function spawnCardDecks()
  ga_event("Game", "spawnCardDecks")
  local factions = Deck:getFactions()
  for _, faction in ipairs(factions) do
    Deck:spawnUnitDeck(faction, {52.43, 1.42, 32.53})
  end
  Deck:spawnUpgradeDeck({52.43, 1.84, 29.23})
  Deck:spawnCommandDeck({52.51, 1.42, 26.35})
  Deck:spawnBattleDeck({52.43, 1.42, 23})
end

function flipObjPos(pObj)
    local objPos = pObj.getPosition()
    local newPos = objPos
    local objRot = pObj.getRotation()
    objRot.y = objRot.y+180
    newPos.x = 8-(objPos.x - 8)
    newPos.z = -objPos.z

    pObj.setPosition(newPos)
    pObj.setRotation(objRot)
end

function flipMap()
    ga_event("Game", "flipMap")
    --Get a list of any objects which are inside of the zone.
    local allObjs = battlefieldZone.getObjects()

    --Check if the table we made is empty due to the zone being empty
    if #allObjs == 0 then
    else
        for _, obj in ipairs(allObjs) do
            -- flip obj
            if obj ~= battlefieldTable then
                flipObjPos(obj)
            end
        end
    end
end

function spawnCustomMap(selectedMap, selectedCartridgeObj, mapMenuCallback, clearZone)
    ga_event("Creative", "spawnCustomMap", selectedMap)
    if mapMenuCallback ~= nil then
        self.call(mapMenuCallback)
    end

    if clearZone ~= false then
        clearZones()
    end

    -- clone cartridge
    local selectedCartridgeObjClone = selectedCartridgeObj.clone({
        position     = {0,-10,0}
    })

    -- get guid
    local selectedCartridgeTable = selectedCartridgeObj.getObjects()

    for i, entry in pairs(selectedCartridgeTable) do
        if entry.name == selectedMap then
            selectedGUID = entry.guid
            break
        end
    end

    selectedCartridgeObjClone.takeObject({
        position       = {0,-10,3},
        callback       = "spawnFromCartridgeDelay",
        callback_owner = self,
        smooth         = false,
        guid           = selectedGUID
    })

    -- delete clone
    destroyObject(selectedCartridgeObjClone)
end

function spawnFromCartridgeDelay(spawnFromCartridgeObj)
    spawnFromCartridgeObj.setLock(true)
    Wait.frames(function()
      spawnMapFromCartridge(spawnFromCartridgeObj, function()
        destroyIfAlive(spawnFromCartridgeObj)
      end)
    end)
end


-- Spawning the whole cartridge in one frame freezes the table for seconds
-- (same failure mode as the list import): pump one object per frame instead,
-- with progress on the screen. onDone runs once the cartridge is drained -
-- callers that destroy the cartridge must do it there, not right after this
-- call returns.
mapDeployGeneration = 0

-- destroyObject raises on an object that is already gone, and a cartridge can
-- disappear while its map is still deploying: a player grabs it, or saving the
-- map sweeps the mount zone. Ask before destroying, and treat an object that
-- cannot answer as already destroyed.
function destroyIfAlive(obj)
  if obj == nil then return end
  local ok, gone = pcall(function() return obj.isDestroyed() end)
  if ok and not gone then
    obj.destroyObject()
  end
end

-- The progress rule along the top of the screen (progressRule in the
-- Global XML, the band every loading indicator of the mod shares). pcall:
-- a save whose XML predates the element must not break a map load.
function mapRuleSet(pct)
  pcall(function()
    UI.setAttribute("progressRuleFill", "width", math.floor(pct) .. "%")
    UI.setAttribute("progressRule", "active", "true")
  end)
end

function mapRuleHide()
  pcall(function() UI.setAttribute("progressRule", "active", "false") end)
end

function spawnMapFromCartridge(selectedCartridge, onDone)
    ga_event("Game", "spawnMapFromCartridge", selectedCartridge.getName())
    clearZones()
    changeBattlefieldTint(selectedCartridge.getTable("battlefieldTint"))
    mapDeployGeneration = mapDeployGeneration + 1
    local generation = mapDeployGeneration
    local total = #selectedCartridge.getObjects()
    local i = 0
    -- onDone always runs, even when the pump gives up: it is what disposes of
    -- the cartridge. Left undone, an abandoned featured-map cartridge stays
    -- parked in the mount zone still holding half a map, and loadMap() picks
    -- it up in place of the player's own. `abandoned` tells the caller not to
    -- touch the screen, which by then belongs to whoever took over.
    local function finish(abandoned)
      mapRuleHide()
      if onDone ~= nil then onDone(abandoned) end
    end
    local function pumpStep()
      -- a newer map load owns the screen and the battlefield now
      if generation ~= mapDeployGeneration then return finish(true) end
      if i >= total then return finish(false) end
      i = i + 1
      -- pcall: the cartridge can vanish mid-cascade (player grabbed it)
      local ok = pcall(function()
        selectedCartridge.takeObject({
          position          = {0,-10-i,0},
          smooth            = false,
          callback_function = function(spawnedObject)
            Wait.frames(function()
              -- This piece was already in flight when another load took over;
              -- placing it now would drop it onto the new map.
              if generation ~= mapDeployGeneration then
                return destroyIfAlive(spawnedObject)
              end
              placeTerrain(spawnedObject)
            end)
          end,
        })
      end)
      -- The player took the cartridge: nobody else owns the screen, so the
      -- menu must come back (the caller then drops its dead disk handle).
      if not ok then return finish(false) end
      if i % 10 == 0 or i == total then
        printToScreen("LOADING MAP...\n\n" .. i .. " / " .. total, 80, 3)
        mapRuleSet(i * 100 / total)
      end
      Wait.frames(pumpStep, 1)
    end
    pumpStep()
end

function clearZones()
    clearMap()
end

function clearMap()

    --Get a list of any objects which are inside of the zone.
    local objectsInZone = battlefieldZone.getObjects()

    --Check if the table we made is empty due to the zone being empty
    if #objectsInZone == 0 then
    else
        --If it isn't empty, we use a for loop to look at each entry in the list
        for _, object in ipairs(objectsInZone) do
            -- destroy object
            if object ~= battlefieldTable then
                destroyObject(object)
            end
        end
    end
end

function prepareToSave()
    -- delete cartridgeObjs
    local mountObjs = mountZone.getObjects()

    for i, obj in pairs(mountObjs) do
        if obj ~= dataDiskMount then
            destroyObject(obj)
        end
    end

    -- create data cartridge
    local spawnPos = dataDiskMount.getPosition()
    -- offset to "snap" the cartridge neatly
    spawnPos.x = spawnPos.x + 0.05
    spawnPos.y = spawnPos.y - 0.41
    spawnPos.z = spawnPos.z + 0.02
    local dataCartridgeOriginal = getObjectFromGUID(gameController.dataCartridgeGUID)

    dataCartridge = dataCartridgeOriginal.clone({
        position     = spawnPos
    })

    dataCartridge.setLock(false)
    dataCartridge.setScale({1,1,1})

    battlefieldTint = gameData.getTable("battlefieldTint")

    local cartridgeScript = "battlefieldTint = {r = " .. battlefieldTint.r .. ", g = " .. battlefieldTint.g .. ", b = " .. battlefieldTint.b .. "}"
    dataCartridge.setLuaScript(cartridgeScript)
end

function saveConditions()
    prepareToSave()

    local zoneBox = getObjectFromGUID(zonesGUIDs.conditions)
    local zoneObjs = zoneBox.getObjects()
    logObj(zoneObjs)
end

function saveMap()
    prepareToSave()

    local zoneBox = getObjectFromGUID(zonesGUIDs.battlefield)
    local zoneObjs = zoneBox.getObjects()
    ga_event("Creative", "saveMap", #zoneObjs)
    logObj(zoneObjs)
end

function logObj(selectedObjs)
    for _, obj in pairs(selectedObjs) do
        if obj.getName() ~= "TABLE" then
            local objLuaScript = getLuaScriptData(obj)

            if string.len(obj.getLuaScript()) > 5 then
                objLuaScript = objLuaScript .. "\nscripted = true"
            else
                objLuaScript = objLuaScript
            end
            obj.setLuaScript(objLuaScript.."\n"..obj.getLuaScript())

            dataCartridge.putObject(obj)
        end
    end
end

function getLuaScriptData(targetObj)
    local returnString = ""

    local returnPos = targetObj.getPosition()
    returnString = returnString .. "position = {x = " .. returnPos.x .. ", y = " .. returnPos.y .. ", z = " .. returnPos.z .. "}\n"

    local returnRot = targetObj.getRotation()
    returnString = returnString .. "rotation = {x = " .. returnRot.x .. ", y = " .. returnRot.y .. ", z = " .. returnRot.z .. "}\n"

    return returnString
end

function loadMap()
    -- get cartridge
    local mountObjs = mountZone.getObjects()

    for i, obj in pairs(mountObjs) do
        if obj.getTable("battlefieldTint") ~= nil then
            loadedCartridge = obj
        end
    end

    -- spawn cartridge
    if loadedCartridge ~= nil then
        clearZones()
        spawnMapFromCartridge(loadedCartridge)
    else
    end
end

function placeTerrain(paObj)
    local spawnPos = paObj.getTable("position")
    local spawnRot = paObj.getTable("rotation")
    -- A cartridge holds where each piece goes in the piece's own script. A
    -- piece saved without one, or whose asset failed to build, has neither -
    -- and setPosition(nil) raises, which used to kill the rest of the map.
    -- Leave it where it landed and name it instead.
    if spawnPos == nil or spawnRot == nil then
      printToAll("Map piece has no saved position: " .. tostring(paObj.getName()))
      return
    end
    paObj.setPosition(spawnPos)
    paObj.setRotation(spawnRot)

    if paObj.getVar("scripted") == true then
    else
        paObj.setLuaScript("")
    end

    if paObj.getName() == "BATTLEFIELD" then
        paObj.interactable = false
        paObj.setLock(true)
        paObj.setLuaScript("function onload() self.interactable = false end")
    end
end

-- UTILITY FUNCTIONS

function dud()
end

function clearAllButtons(exception)
    for _, optionObjEntry in pairs(optionObjs) do
        optionObjEntry.clearButtons()
    end

    for _, optionButtonEntry in pairs(optionButtons) do
        optionButtonEntry.clearButtons()
        optionButtonEntry.setColorTint({0,0,0})
    end

    if exception ~= backButton then
        backButton.clearButtons()
        backButton.setColorTint({0,0,0})
    end

    prevButton.clearButtons()
    prevButton.setColorTint({0,0,0})
    nextButton.clearButtons()
    nextButton.setColorTint({0,0,0})
end

function printToScreen(screenText, fontSize, selectedAlignment)
    screen.editButton({
        int = 0, click_function = "dud", function_owner = self, label = screenText, position = {0.9, 0.25, 0}, rotation = {0, -90, 90}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = fontSize, font_color = {0.8867, 0.7804, 0, 1}, alignment = selectedAlignment
    })
end

function createOptionButton(optionNumber, optionClickFunction, optionLabel, optionToolTip,tint)
    optionObj = optionObjs["gameControllerOption"..optionNumber]
    optionButton = optionButtons["gameControllerOption"..optionNumber.."Button"]

    _G["gameControllerOptionFunction"..optionNumber] = function()
        optionButtons["gameControllerOption"..optionNumber.."Button"].AssetBundle.playTriggerEffect(0)
        _G[optionClickFunction](optionNumber)
    end
    local stringLength = string.len(optionLabel)

    if stringLength < 24 then
        buttonFontSize = 400
    else
        local stringDif = stringLength - 22
        buttonFontSize = 400 - (stringDif * 8)
    end

    optionObj.createButton({
        click_function = "gameControllerOptionFunction"..optionNumber, function_owner = self, label = optionLabel, position = {-0.35, 0.3, 0}, scale = {0.5, 0.5, 0.5}, width = 4200, height = 600, font_size = buttonFontSize, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100},tooltip = optionToolTip
    })

    optionButton.createButton({
        click_function = "gameControllerOptionFunction"..optionNumber, function_owner = self, label = "", position = {0, 0.65, 0}, width = 1400, height = 1400, font_size = 1100, color = {1,1,1,0.01},font_color = {1,1,1,100}, tooltip = optionToolTip, alignment = 3
    })

    optionButton.setColorTint(tint)
end

function changeBackButton(optionClickFunction, optionToolTip)
    _G["gameControllerBackButtonFunction"] = function()
        backButton.AssetBundle.playTriggerEffect(0)
        _G[optionClickFunction]()
    end

    backButton.createButton({
        click_function = "gameControllerBackButtonFunction", function_owner = self, label = "BACK", position = {0, 0.65, 0}, scale = {1, 1, 1.4}, width = 1500, height = 2000, font_size = 400, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100}, tooltip = optionToolTip
    })
    backButton.setColorTint({1,0,0})
end

function changeNextButton(optionClickFunction, optionToolTip)
    _G["gameControllerNextButtonFunction"] = function()
        nextButton.AssetBundle.playTriggerEffect(0)
        _G[optionClickFunction]()
    end

    nextButton.createButton({
        click_function = "gameControllerNextButtonFunction", function_owner = self, label = "NEXT", position = {0, 0.65, 0}, scale = {1, 1, 0.7}, width = 1500, height = 2000, font_size = 400, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100}, tooltip = optionToolTip
    })
    nextButton.setColorTint({0.7,0.7,0})
end

function changePrevButton(optionClickFunction, optionToolTip)
    _G["gameControllerPrevButtonFunction"] = function()
        prevButton.AssetBundle.playTriggerEffect(0)
        _G[optionClickFunction]()
    end

    prevButton.createButton({
        click_function = "gameControllerPrevButtonFunction", function_owner = self, label = "PREV", position = {0, 0.65, 0}, scale = {1, 1, 0.7}, width = 1500, height = 2000, font_size = 400, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100}, tooltip = optionToolTip
    })
    prevButton.setColorTint({0.7,0.7,0})
end

optionUrls = {}

function downloadMap(mapIndex)
  local url = optionUrls[mapIndex]
  printToScreen("DOWNLOADING MAP...")
  downloadMapByUrl(url)
end

-- cloud-3.steamusercontent.com is gone (HTTP 403 on everything); Steam now
-- serves the same UGC paths from Akamai. Repair both the map URL itself and
-- every asset URL inside the downloaded map JSON.
--
-- Six assets never made it to Akamai (404 on every host, gone from the
-- Wayback Machine too). The community map packs ship the same terrain
-- pieces under other UGC paths, so swap the dead paths for those live
-- equivalents.
DEAD_UGC_SWAPS = {
  -- Scarif Landing, "Sand Mound (Blast Hole)": the league packs use the
  -- plain Sand Mound assets for the same piece.
  ["866242507558372594/6E91C689398356425C48138EC9FD73DD213DBE25"] =
    "785234540542465659/30348E08551EAA3E8D5164E0D2931B3EB72DCEC1",
  ["874120511627020981/C8D3FAC8EFDCDB836ECC7E1B74C7929F6C77F5EF"] =
    "785234540542470239/CFB22A69010911784880172594A7106CBC1F8DF1",
  ["874120913887641068/75C737DD596381693CCA671B3BD6A1D227CCBBB8"] =
    "785234540542467139/4036C31123FF00D2459B3ED1E57CD8141ACFAC8D",
  -- Geonosis, "Destroyed Advanced Dwarf Spider Droid": not substituted here.
  -- The only other copy in circulation is a different sculpt whose texture
  -- does not match; the original files are served from our store instead,
  -- see MIRRORED_ASSETS.
  -- Imperial Checkpoint, "Walkway [Light Cover]" state 1: collider of the
  -- same walkway mesh as found in the other packs.
  ["924802058713318404/E46A0DB14CBAD8B6711484041D221EC8DFE6498A"] =
    "785234780857945420/BD98F26583D35B354CE52BC7F624EFD69FF167A7",
  -- Geonosis, rock formation: the map data pasted the collider gist URL
  -- twice in a row in one ColliderURL field.
  ["rock_formation_collider.txthttps://gist.githubusercontent.com/nashjaee/3375e9ebe255d751196483c59c545591/raw/fe2fa562af6874076a3dc4e0f74dc7c68eeafa63/rock_formation_collider.txt"] =
    "rock_formation_collider.txt",
  -- Imperial Checkpoint: wildtextures.com no longer serves this jpg (404
  -- page). The copy the Wayback Machine kept is served from our own host,
  -- with the other repaired assets, rather than from the archive.
  ["http://www.wildtextures.com/wp-content/uploads/wildtextures-tiles-stone-marble-480x279.jpg"] =
    "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/imperial_checkpoint_marble.jpg",
  -- Geonosis: infinitebucket.com is gone, dead DNS, and no copy survives in
  -- any cache or archive. The drifting dust is rebuilt instead (a low veil
  -- and gusts that curl into a ring, Windows and Mac in one bundle), served
  -- from our own host. The map places it flipped and stretched; the bundle
  -- is built for that exact transform.
  ["http://infinitebucket.com/tts/scenesystem/dust.unity3d"] =
    "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/geonosis_dust_v2.unity3d",
}

-- Featured Map assets whose hosts nobody controls any more: personal imgur
-- accounts, one map author's Dropbox, anonymous gists, a pastebin, a texture
-- site. Every one of them still answered when the mirror was taken, which is
-- exactly the moment to copy a file rather than the moment after. Keyed by
-- the URL the map data carries, verbatim; the value is the file name in our
-- store. The assets these same maps pull from Steam's CDN are left alone:
-- that is the host the whole mod already rests on, so mirroring them would
-- buy no safety and cost 58 MB. The exception is the two Steam files that
-- did die, keyed by their address after the cloud-3 rewrite.
MIRRORED_ASSETS = {
  -- gist.githubusercontent.com, 32 assets
  ["https://gist.githubusercontent.com/anonymous/21580f275647bee8b795e4f3bfc67bef/raw/ed056d56c03562c9779f838598cf2db9fa5abcee/gistfile1.txt"] =
    "1f4c229eed10d4d5411e.obj",
  ["https://gist.githubusercontent.com/anonymous/25165671cdebaa76438811abedfd9a6b/raw/17b0dd36856080bb407f53c7e4cf05ff196434a1/gistfile1.txt"] =
    "50d82c6c0a22114b2054.obj",
  ["https://gist.githubusercontent.com/anonymous/2c89c53f43dca7ad8d67f3ee45049f0a/raw/2814f977fbd2fc74eae8c75298ee88addd5adc7f/gistfile1.txt"] =
    "1f550534a37b445056a6.obj",
  ["https://gist.githubusercontent.com/anonymous/90c71337b0c80ad2db5fa29bb4818a01/raw/76fbc223e3663c9c572d971bfc899ddfc4c704b7/gistfile1.txt"] =
    "32e2556293ac3d850008.obj",
  ["https://gist.githubusercontent.com/nashjaee/0ae48450370150c2c00027895b8e82ba/raw/a1a792c26c857ffd87aba6787c33a932fed0946c/rock_formation_2_model.txt"] =
    "3b4256e87e064eca2c3f.obj",
  ["https://gist.githubusercontent.com/nashjaee/1724038bcd1af36165d9c2b831aa1986/raw/a75963b487ef88b438f688b68bef314545da2fe8/tat_small_lodge.txt"] =
    "aa6a85f5695cbeee469f.obj",
  ["https://gist.githubusercontent.com/nashjaee/1dd4657643079c5fe4410c169c452c45/raw/133d719e27011b958e5873f466cdae4ce62e44b2/short_long_curve.txt"] =
    "6e0d8984ce8d11145821.obj",
  ["https://gist.githubusercontent.com/nashjaee/1e074019b743cc3c4e56dc0dca696629/raw/156f662d4ae92509be2950d36d2ed9babd626dd8/wide_arch.txt"] =
    "86dab0221e7c4b6b4de9.obj",
  ["https://gist.githubusercontent.com/nashjaee/31a2f65534f55c298b97768d85c6d7ed/raw/039d1f64c1764ecf6ce52b7dbb967e299884e597/short_tight_90.txt"] =
    "6c35562d0e038872a6c4.obj",
  ["https://gist.githubusercontent.com/nashjaee/39efab0cd1f7f06bebe96234166a7e5f/raw/bf1cb1943f287af6cc925fe89f676022393b1ca6/trench_holdout_model.txt"] =
    "700c83442cf4dcb2163e.obj",
  ["https://gist.githubusercontent.com/nashjaee/3bf24876e6e170127cce6049880595bd/raw/7aa374631f2d94ecee9421d919a43391de68a0b4/tat_shop_full.txt"] =
    "1501e8c83827a64eb096.obj",
  ["https://gist.githubusercontent.com/nashjaee/4244c1f23225cd174f87dc6c43c9e60f/raw/50a19f25736e7be3838bec97fe82cdb6561196da/single_arch.txt"] =
    "cb0a3effd92131013920.obj",
  ["https://gist.githubusercontent.com/nashjaee/4c26247df7714072af9707c52c32a095/raw/3cf1204ec97d97f21b27de644f73e2ae6af29f9a/tat_medium_3.txt"] =
    "2c247daa66d2c5315b89.obj",
  ["https://gist.githubusercontent.com/nashjaee/4cd8db9491c9f804b679a0c07d995a47/raw/d6e211548521cd3c386e2d29e11a8e13945c4115/sand_mound_model.txt"] =
    "762ca9a92c0f28849df1.obj",
  ["https://gist.githubusercontent.com/nashjaee/4ffd951d975d58e376008d40acf0e6be/raw/f50c06ac2c28caa07251b0f96a6a56fc5dfbf727/laat_model.txt"] =
    "7d5659552c084348cd1b.obj",
  ["https://gist.githubusercontent.com/nashjaee/5bc7ec9cde6042692360b7eccaccaddb/raw/06085b5165429a6fc20baa3044ac8d58e29a8f74/laat_collider.txt"] =
    "a01bf806466dbd0d982e.obj",
  ["https://gist.githubusercontent.com/nashjaee/669805574c4b9f7b04e785509a928033/raw/0c48b07b3101513396567a27960f733c20ab61ac/double_arch.txt"] =
    "868cc2a27f8b8d15eeb0.obj",
  ["https://gist.githubusercontent.com/nashjaee/7d1f66af25c773fb9f40571a3dcbc329/raw/bccbcb2a8596129534c1f7db3d01482e34f0a4a8/short_45.txt"] =
    "e551c98351b071275e0e.obj",
  ["https://gist.githubusercontent.com/nashjaee/7e385a5d880f7ec4ffe54c01aec70077/raw/78ddb6a1681b62fa80966a5e9f9b2cca863829c0/tat_medium_lodge.txt"] =
    "de819f7854b5bc1cd2b0.obj",
  ["https://gist.githubusercontent.com/nashjaee/8353f629e1d7e1d213fbe564be21de8e/raw/b20462e946ced3eee4f8260d3b28565e397d800b/gistfile1.txt"] =
    "0034a902133f5f57d594.obj",
  ["https://gist.githubusercontent.com/nashjaee/849ec6905a7613c0e656db6e364f8148/raw/48a785f51bbc29ee603725bff2c9ca240f64728e/barricade_model.txt"] =
    "8efba609d07d40d69db1.obj",
  ["https://gist.githubusercontent.com/nashjaee/8a3c5c11d816ad853a5485e63dffff48/raw/09c0ea0fdb74453156070ab594aa2f9b26af3cef/sand_mound_collider.txt"] =
    "9b5d02602c38a5ec45a9.obj",
  ["https://gist.githubusercontent.com/nashjaee/8c5ce4aca7e9cba562148ec0a2c438e5/raw/4ca2b165bab93fd9bc9537042941d85d1e6fe1b6/rock_formation_model.txt"] =
    "7eb212dfa3d9a5ad0d73.obj",
  ["https://gist.githubusercontent.com/nashjaee/a3fea17003835d745cefe356b141250b/raw/54bb87ed3ae3ee7ec3e8080150efd077b75d998b/tat_tower_v2.txt"] =
    "b795942d99cb522ee6dd.obj",
  ["https://gist.githubusercontent.com/nashjaee/b5f868e1a32dd277e804ba5243140395/raw/094ee931f3514d97f4ca7f1ff4c812333fbc297a/short_straight.txt"] =
    "fd8e88dfa63fabc182ae.obj",
  ["https://gist.githubusercontent.com/nashjaee/b93cdf53600ef76b4b425fc4f4b92103/raw/528b054fc44fd3573b055b74600e71c338cb0d25/short_90_corner.txt"] =
    "24eaad127a589e4436d8.obj",
  ["https://gist.githubusercontent.com/nashjaee/c16261972363a0bcb9f59a763fc0f771/raw/0cf50b5b1c66b4d4969bc7b37f4f92bfc6074059/tat_medium_house_2.txt"] =
    "b614cbc1f38917aafc92.obj",
  ["https://gist.githubusercontent.com/nashjaee/ca9fd90e500b9407bd90c69484b2573b/raw/2d401c49841c1b3f32e776fb32f594a09d0f5b91/tat_small_house_2.txt"] =
    "2c3ae8aee7ab0d06142f.obj",
  ["https://gist.githubusercontent.com/nashjaee/e42f6c8204c6f15a4287cc37667f580b/raw/4ad498090fa0d76e124b102fed2a3e77bca38653/tall_long_curve.txt"] =
    "7c0920e705698a03804e.obj",
  ["https://gist.githubusercontent.com/nashjaee/ed99cb7b59e12459e160131fee87940b/raw/328aae577da949dfd45dd7a13fcbabd88e663954/tat_outpost_full.txt"] =
    "5f3486e8c1fa6cc99351.obj",
  -- i.imgur.com, 13 assets
  ["http://i.imgur.com/WdMBT2e.jpg"] =
    "b4060a6535d59b65f4a0.jpg",
  ["https://i.imgur.com/0awZWbG.jpg"] =
    "e2be2ac91c939dc065fa.jpg",
  ["https://i.imgur.com/0gTJWaK.jpg"] =
    "1d8ba5e38e30b50b43cc.jpg",
  ["https://i.imgur.com/GViH5JN.jpg"] =
    "751f8037054118ab2af5.jpg",
  ["https://i.imgur.com/M7wiIIi.jpg"] =
    "1dbb93d8056257279852.jpg",
  ["https://i.imgur.com/NqvTeah.jpghttps://i.imgur.com/NqvTeah.jpg"] =
    "ddc83f990cf23d695da3.jpg",
  ["https://i.imgur.com/PF3rjzI.jpg"] =
    "c2584766e7ec93897965.jpg",
  ["https://i.imgur.com/PF3rjzI.jpghttps://i.imgur.com/PF3rjzI.jpg"] =
    "a9029d507c965fdea1d1.jpg",
  ["https://i.imgur.com/XtMvQGI.png"] =
    "73f05486a1b772ab6b99.png",
  ["https://i.imgur.com/XuuDLys.jpg"] =
    "b5267a49ccd8774a21d1.jpg",
  ["https://i.imgur.com/szfypFE.jpghttps://i.imgur.com/szfypFE.jpg"] =
    "80e6ab9b6871aabbea63.jpg",
  ["https://i.imgur.com/xJTsMo6.jpghttps://i.imgur.com/xJTsMo6.jpg"] =
    "0838aa4b46f18f53052c.jpg",
  ["https://i.imgur.com/yKymdqE.jpghttps://i.imgur.com/yKymdqE.jpg"] =
    "5a40760081d3e3bfc205.jpg",
  -- paste.ee, 1 asset
  ["https://paste.ee/r/JavTd"] =
    "0e87f1e304d4059f862e.obj",
  -- texturelib.com, 1 asset
  ["http://texturelib.com/Textures/brick/pavement/brick_pavement_0100_02_preview.jpg"] =
    "576783db1c59922d8b22.jpg",
  -- web.archive.org, 1 asset
  ["http://web.archive.org/web/20230807160829im_/https://wildtextures.com/wp-content/uploads/wildtextures-tiles-stone-marble-480x279.jpg"] =
    "397917691ba45bb7f1a8.jpg",
  -- steamusercontent-a.akamaihd.net, 2 assets: Geonosis, "Destroyed
  -- Advanced Dwarf Spider Droid", gone from Steam; the original mesh (also
  -- its collider) and texture, recovered byte for byte from a player's cache
  ["https://steamusercontent-a.akamaihd.net/ugc/969858026283571281/F2359F847B4DFF3757D2AE27D90480A062890466/"] =
    "969858026283571281_F2359F847B4D.obj",
  ["https://steamusercontent-a.akamaihd.net/ugc/969858026283571356/2E74A89F1E80B0645764DC1B94BF4ADC2940AAAC/"] =
    "969858026283571356_2E74A89F1E80.png",
  -- www.dropbox.com, 14 assets
  ["https://www.dropbox.com/s/3knbhrp9h49h5df/speeder%20roadster.obj?dl=1"] =
    "5bd9ceba2cd576cd70c9.bin",
  ["https://www.dropbox.com/s/4lkjcjnxa21z407/gun.obj?dl=1"] =
    "55cc846737b52de8404c.bin",
  ["https://www.dropbox.com/s/6dv3zim10qstual/medium_3.jpg?raw=1"] =
    "4798c2a373b74ef9658f.jpg",
  ["https://www.dropbox.com/s/d61jptcthjui75q/B69_Rubble3_JVG.png?dl=1"] =
    "8f50d047ee9fd92195f3.bin",
  ["https://www.dropbox.com/s/g5xw10wwhisrz29/decimator%20imperial%20star%20ship.obj?dl=1"] =
    "ec02e571d877ac090336.bin",
  ["https://www.dropbox.com/s/id436qh9za4v75h/Landspeeder%20texture.jpg?dl=1"] =
    "798a5a7d14437698fd3d.bin",
  ["https://www.dropbox.com/s/mkgnnbg2ws09exc/shop_full.jpg?raw=1"] =
    "4a042086373b17156b63.jpg",
  ["https://www.dropbox.com/s/pxxf15m633krun2/tower_v2.jpg?raw=1"] =
    "8f1d88395678296bce91.jpg",
  ["https://www.dropbox.com/s/qsq43ti5qlhq7dx/medium_house_2.jpg?raw=1"] =
    "5fa9f342f8c0e7a9863d.jpg",
  ["https://www.dropbox.com/s/rlxu8ft2dq16dnl/medium_lodge.jpg?raw=1"] =
    "a7c0577699378fcfa1f5.jpg",
  ["https://www.dropbox.com/s/rtdlpenu65l37b9/tatooine_generic.jpg?raw=1"] =
    "f41fbb395aac8ece2624.jpg",
  ["https://www.dropbox.com/s/t05k9nedv8uim24/small_house_2.jpg?raw=1"] =
    "b8e92c04d455714c0ec1.jpg",
  ["https://www.dropbox.com/s/vkw5xgi965vook5/small_lodge.jpg?raw=1"] =
    "e709845ea005042693db.jpg",
  ["https://www.dropbox.com/s/zsumfl6t4z51i2o/outpost_full.jpg?raw=1"] =
    "eb6ae4de00d00f4bd03f.jpg",
}

-- Where our copies are served from. One flat directory, under a contract that
-- nothing in it is ever renamed, overwritten or deleted - see the swl-assets
-- store - so these addresses never have to move again.
ASSET_STORE = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/"

local function applySwaps(text, swaps, prefix)
  -- Longest key first. Some map data carries a URL pasted twice in a row,
  -- and the table has a key for the doubled form as well as the single one:
  -- run the single one first and it rewrites both halves of the doubled
  -- URL, which then matches nothing and reaches TTS as two of our addresses
  -- glued together. pairs() gives no order, and MoonSharp's differs from
  -- stock Lua's, so the order has to be explicit.
  local keys = {}
  for from in pairs(swaps) do
    table.insert(keys, from)
  end
  table.sort(keys, function(a, b)
    return #a > #b or (#a == #b and a < b)
  end)
  for _, from in ipairs(keys) do
    local to = swaps[from]
    -- A gsub rebuilds the whole string, and a map file is 70-160 KB, so never
    -- run one blind: a map carries at most a couple of these. Escape only the
    -- ones that hit - gsub wants the magic characters quoted, find wants the
    -- raw text.
    if text:find(from, 1, true) then
      local into = (prefix or "") .. to
      text = text:gsub(from:gsub("%W", "%%%0"), (into:gsub("%%", "%%%%")))
    end
  end
  return text
end

-- Terrain whose collider is a flat plate on the ground, or a rough block
-- that misses the model: minis dropped through bridges, crates and walls, or
-- stood off the rocks. Each gets a collider made of convex pieces cut from
-- the model itself (Mod TTS SWL/make_terrain_colliders.py). They only work
-- as one mesh with Convex off: a single convex hull of them all would fill
-- the arches and the space under the bridges. Keyed by the model, not by
-- the old collider: the two Scarif outpost walls are different models that
-- share one. Area terrain - Holo Ads, Cargo Pallets, Ruins, the Jedha
-- barricades, woods - keeps its plate on purpose: minis stand inside it.
TERRAIN_COLLIDERS = {
  -- Barricade [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234780864397132/F696994B2A4CE38EA3D5928C17543CB11630C072/"] =
    "collider_scarif_barricade_v1.obj",
  -- Bespin Wall (High Stone Wall) [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540542509494/8CA403F2ACD4BF21A2A42AD20809239A4A0C60BF/"] =
    "collider_bespin_wall_half_moon_v1.obj",
  -- Bespin Wall (High Stone Wall) [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540542571500/3E825CA67AF0A048127E8E0A08B5C105D1E98588/"] =
    "collider_bespin_wall_straight_v1.obj",
  -- Bridge Walkway [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/966480765117279505/8182E3A340062698877307FC66C2163E1D34711C/"] =
    "collider_bridge_walkway_v1.obj",
  -- Building [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/966480765117277880/2D1CC9AE9EE1B583ECBA13328DA1BE93D1D175B5/"] =
    "collider_building_small_v1.obj",
  -- Cargo Crates [Light Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540542832033/58B168E2A63745DB7AA2BD9A6182709416576DBB/"] =
    "collider_cargo_crates_stack_v1.obj",
  -- Landing Bay Archway [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540546190104/855BF67B705B962579C4A39ACAB4FE330CF00ED8/"] =
    "collider_landing_bay_archway_v1.obj",
  -- Landing Bay Loading Door [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540546190513/71CCB9F68D1ECBC9273FA105D7DC6D9EDE3D96C0/"] =
    "collider_landing_bay_loading_door_v1.obj",
  -- Moisture Vaporator [Light Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234780858650890/E974F7F12BA33FEA0C4BF337030EFF56CCBB514A/"] =
    "collider_moisture_vaporator_v1.obj",
  -- Outpost Wall Lvl 2 (High Stone Wall) [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540546189005/6BA05494E29AE2107927C5B66A40D74552961B9E/"] =
    "collider_outpost_wall_b_v1.obj",
  -- Outpost Wall Lvl 2 (High Stone Wall) [Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540546188381/4504550673E1F3490F323C751CA9ED67F2EF8220/"] =
    "collider_outpost_wall_a_v1.obj",
  -- Rock Formation [Heavy Cover]
  ["https://gist.githubusercontent.com/nashjaee/0ae48450370150c2c00027895b8e82ba/raw/a1a792c26c857ffd87aba6787c33a932fed0946c/rock_formation_2_model.txt"] =
    "collider_rock_formation_large_v1.obj",
  -- Rock Formation [Heavy Cover]
  ["https://gist.githubusercontent.com/nashjaee/8c5ce4aca7e9cba562148ec0a2c438e5/raw/4ca2b165bab93fd9bc9537042941d85d1e6fe1b6/rock_formation_model.txt"] =
    "collider_rock_formation_pillar_v1.obj",
  -- T-65 X-Wing [Light/Heavy Cover]
  ["https://steamusercontent-a.akamaihd.net/ugc/785234540542754362/7AAD7B25F1A8C2CDBD05B3444E42CA0801A35BD7/"] =
    "collider_xwing_wreck_v1.obj",
}

-- One walk over the models of the map, and only when one of ours is in it.
-- Runs before MIRRORED_ASSETS, which would otherwise move the two rocks to
-- their mirrored copies first. Plain finds only: a pattern stretching across
-- a CustomMesh block is "too complex" for MoonSharp, though stock Lua takes
-- it. In a block, ColliderURL comes after MeshURL and Convex right after it.
local function applyTerrainColliders(text)
  local hit = false
  for mesh in pairs(TERRAIN_COLLIDERS) do
    if text:find(mesh, 1, true) then
      hit = true
      break
    end
  end
  if not hit then return text end
  local out, from, pos = {}, 1, 1
  while true do
    local key = text:find('"MeshURL":', pos, true)
    if not key then break end
    local open = text:find('"', key + 10, true)
    local close = open and text:find('"', open + 1, true)
    if not close then break end
    pos = close + 1
    local file = TERRAIN_COLLIDERS[text:sub(open + 1, close - 1)]
    if file then
      local nextMesh = text:find('"MeshURL":', pos, true) or #text + 1
      local collider = text:find('"ColliderURL":', pos, true)
      local cOpen = collider and text:find('"', collider + 14, true)
      local cClose = cOpen and text:find('"', cOpen + 1, true)
      local convex = cClose and text:find('"Convex":', cClose, true)
      local vStart = convex and text:find("%a", convex + 9)
      local vEnd = vStart and text:find("%A", vStart)
      if vEnd and vEnd < nextMesh then
        table.insert(out, text:sub(from, cOpen))
        table.insert(out, ASSET_STORE .. file)
        table.insert(out, text:sub(cClose, vStart - 1))
        table.insert(out, "false")
        from, pos = vEnd, vEnd
      end
    end
  end
  table.insert(out, text:sub(from))
  return table.concat(out)
end

-- Terrain set back by hand, in game, on the five competitive maps: walls,
-- buildings, crates, rocks, and the Scarif blast holes, which the map saves
-- slightly too high. One Geonosis building was widened as well. A map places each piece from the position and rotation
-- in its own script (placeTerrain), so that text is what gets fixed, and the
-- pair is the key: no two pieces share it, while a rotation alone can repeat.
-- Read live from the table by Mod TTS SWL/outils-tts-direct/releve_decors.py.
MAP_POSITION_FIXES = {
  -- competitive-bespin-gardens
  ["position = {x = -16.3444690704346, y = 2.21026754379272, z = 11.3314151763916}\\nrotation = {x = -0.000422634679125622, y = 45.0045280456543, z = 0.000462515163235366}"] =
    "position = {x = -16.734976, y = 2.210261, z = 11.460049}\\nrotation = {x = -0.0004, y = 45.0045, z = 0.0005}",
  ["position = {x = -19.7279396057129, y = 2.20242381095886, z = 8.65326595306396}\\nrotation = {x = 0.00283986399881542, y = 90.0007400512695, z = 0.000373695424059406}"] =
    "position = {x = -20.118446, y = 2.202417, z = 8.781899}\\nrotation = {x = 0.0028, y = 90.0007, z = 0.0004}",
  ["position = {x = -17.4243354797363, y = 2.17950010299683, z = 8.18620204925537}\\nrotation = {x = -0.00128965429030359, y = 0.00767629314213991, z = 0.00143355946056545}"] =
    "position = {x = -17.814842, y = 2.179494, z = 8.314836}\\nrotation = {x = -0.0013, y = 0.0077, z = 0.0014}",
  ["position = {x = -10.2407531738281, y = 1.44165706634521, z = 4.28046751022339}\\nrotation = {x = -0.000749535334762186, y = 135.001892089844, z = -0.0013011391274631}"] =
    "position = {x = -9.271084, y = 1.441676, z = 3.310735}\\nrotation = {x = -0.0007, y = 135.0019, z = -0.0013}",
  ["position = {x = -2.05993676185608, y = 1.44165325164795, z = 4.13773822784424}\\nrotation = {x = -0.000735168345272541, y = 225.007843017578, z = 0.000966997700743377}"] =
    "position = {x = -2.958774, y = 1.441672, z = 3.239148}\\nrotation = {x = -0.0007, y = 225.0078, z = 0.0010}",
  ["position = {x = -1.99412715435028, y = 1.44140803813934, z = -4.3311014175415}\\nrotation = {x = 359.994201660156, y = 314.997161865234, z = 0.00198409776203334}"] =
    "position = {x = -3.020032, y = 1.441555, z = -3.305299}\\nrotation = {x = 359.9942, y = 314.9972, z = 0.0020}",
  ["position = {x = -10.2578134536743, y = 1.44141268730164, z = -4.16398906707764}\\nrotation = {x = 359.994232177734, y = 45.0047874450684, z = -0.000285362999420613}"] =
    "position = {x = -9.346426, y = 1.441542, z = -3.252754}\\nrotation = {x = 359.9942, y = 45.0048, z = -0.0003}",
  ["position = {x = 17.3822784423828, y = 1.42471396923065, z = 9.27560997009277}\\nrotation = {x = -0.00113139906898141, y = 45.0005035400391, z = -0.00117082835640758}"] =
    "position = {x = 18.307821, y = 1.424665, z = 7.521829}\\nrotation = {x = -0.0011, y = 45.0005, z = -0.0012}",
  ["position = {x = 25.9971103668213, y = 1.44184029102325, z = 9.93169975280762}\\nrotation = {x = 0.00113579339813441, y = 225.000610351563, z = 0.00113226601388305}"] =
    "position = {x = 26.432467, y = 1.441873, z = 11.121146}\\nrotation = {x = 0.0011, y = 225.0006, z = 0.0011}",
  ["position = {x = -22.5605716705322, y = 1.441561460495, z = -0.0226113721728325}\\nrotation = {x = 0.00112651311792433, y = 225.016616821289, z = 0.00113310944288969}"] =
    "position = {x = -22.849058, y = 1.441516, z = -1.609650}\\nrotation = {x = 0.0011, y = 225.0166, z = 0.0011}",
  ["position = {x = 8.27384376525879, y = 1.4418785572052, z = 11.3060216903687}\\nrotation = {x = 0.00113677675835788, y = 224.999420166016, z = 0.0011350535787642}"] =
    "position = {x = 7.656243, y = 1.441837, z = 9.786139}\\nrotation = {x = 0.0011, y = 224.9994, z = 0.0011}",
  ["position = {x = -17.5987339019775, y = 1.43836259841919, z = 10.2772045135498}\\nrotation = {x = -0.00116937689017504, y = 45.0006980895996, z = -0.00149376923218369}"] =
    "position = {x = -17.989241, y = 1.438356, z = 10.405838}\\nrotation = {x = -0.0012, y = 45.0007, z = -0.0015}",
  -- competitive-geonosis-badlands-of-ngzi
  ["position = {x = -17.8894748687744, y = 1.44561731815338, z = 4.18127107620239}\\nrotation = {x = 8.22549482109025E-05, y = 90.0083389282227, z = 0.000316305144224316}"] =
    "position = {x = -17.695518, y = 1.445619, z = 3.804952}\\nrotation = {x = 0.0001, y = 90.0083, z = 0.0003}",
  ["position = {x = 37.3077049255371, y = 1.44560122489929, z = -7.42593193054199}\\nrotation = {x = 0.000323771499097347, y = 14.997953414917, z = -8.37857271562825E-07}"] =
    "position = {x = 37.276752, y = 1.445609, z = -9.125908}\\nrotation = {x = 0.0003, y = 14.9980, z = 0.0000}",
  ["position = {x = 37.3225975036621, y = 1.44561731815338, z = -10.3838348388672}\\nrotation = {x = 0.000280667329207063, y = 344.9873046875, z = -0.000163672200869769}"] =
    "position = {x = 37.291645, y = 1.445625, z = -12.083809}\\nrotation = {x = 0.0003, y = 344.9873, z = -0.0002}",
  ["position = {x = 12.4329710006714, y = 1.44562435150146, z = -5.12111330032349}\\nrotation = {x = 0.000228284814511426, y = 59.9912452697754, z = 0.000230361518333666}"] =
    "position = {x = 13.780688, y = 1.448051, z = -4.856693}\\nrotation = {x = 0.0002, y = 59.9912, z = 0.0002}",
  ["position = {x = 11.9253168106079, y = 1.44891059398651, z = 7.5784969329834}\\nrotation = {x = 0.000323634129017591, y = 14.9799213409424, z = 1.18821697014937E-06}"] =
    "position = {x = 12.617463, y = 1.448182, z = 9.036596}\\nrotation = {x = 0.0003, y = 14.9799, z = 0.0000}",
  ["position = {x = 12.0082731246948, y = 1.69295477867126, z = 7.48281621932983}\\nrotation = {x = -0.000224448522203602, y = 150.009735107422, z = 0.000225987285375595}"] =
    "position = {x = 12.242166, y = 1.692950, z = 8.356935}\\nrotation = {x = -0.0002, y = 150.0097, z = 0.0002}",
  ["position = {x = -13.9681158065796, y = -1.45426392555237, z = -13.0905914306641}\\nrotation = {x = -0.00031470219255425, y = 210.005142211914, z = -8.66435002535582E-05}"] =
    "position = {x = -12.608698, y = -1.454262, z = -11.673169}\\nrotation = {x = -0.0003, y = 210.0051, z = -0.0001}",
  ["position = {x = -17.8105010986328, y = 2.00989484786987, z = -4.80733013153076}\\nrotation = {x = -1.24142479762668E-05, y = 209.993103027344, z = -0.000124197380500846}"] =
    "position = {x = -16.693413, y = 2.009895, z = -2.504614}\\nrotation = {x = 0.0000, y = 209.9931, z = -0.0001}",
  ["position = {x = -13.9740467071533, y = -0.436341643333435, z = -14.8254880905151}\\nrotation = {x = 8.62655069795437E-05, y = 300.009185791016, z = -0.000313346856273711}"] =
    "position = {x = -12.614628, y = -0.436339, z = -13.408067}\\nrotation = {x = 0.0001, y = 300.0092, z = -0.0003}",
  ["position = {x = -16.0225372314453, y = -0.560887575149536, z = -5.86472845077515}\\nrotation = {x = -0.00343916448764503, y = 29.9756145477295, z = 0.000104584090877324}"] =
    "position = {x = -14.905517, y = -0.560889, z = -3.562011}\\nrotation = {x = -0.0034, y = 29.9756, z = 0.0001}",
  ["position = {x = 25.1808490753174, y = 1.62697184085846, z = -5.21770620346069}\\nrotation = {x = 359.36279296875, y = 176.583312988281, z = 4.44668865203857}"] =
    "position = {x = 25.635326, y = 1.627033, z = -5.599424}\\nrotation = {x = 359.3628, y = 176.5833, z = 4.4467}",
  ["position = {x = 24.7082538604736, y = 1.55383205413818, z = -8.63409614562988}\\nrotation = {x = -0.00296533550135791, y = 89.9867172241211, z = 0.00555519573390484}"] =
    "position = {x = 25.162731, y = 1.553893, z = -9.015818}\\nrotation = {x = -0.0030, y = 89.9867, z = 0.0056}",
  ["position = {x = 21.4139060974121, y = 1.5537132024765, z = -9.16911506652832}\\nrotation = {x = -0.00555722462013364, y = 180.013107299805, z = -0.00297248386777937}"] =
    "position = {x = 21.868383, y = 1.553774, z = -9.550837}\\nrotation = {x = -0.0056, y = 180.0131, z = -0.0030}",
  ["position = {x = 23.2676067352295, y = 1.4493590593338, z = -6.61688137054443}\\nrotation = {x = -0.00250400276854634, y = 85.28076171875, z = 0.00578292645514011}"] =
    "position = {x = 23.812904, y = 1.449453, z = -7.243096}\\nrotation = {x = -0.0025, y = 85.2808, z = 0.0058}",
  ["position = {x = 22.7908420562744, y = -1.86076688766479, z = -4.03271579742432}\\nrotation = {x = 2.94338321685791, y = 102.006393432617, z = 328.662750244141}"] =
    "position = {x = 23.262270, y = -1.860684, z = -4.583440}\\nrotation = {x = 2.9434, y = 102.0064, z = 328.6628}",
  ["position = {x = 20.8313465118408, y = 1.55313265323639, z = -3.4971866607666}\\nrotation = {x = -0.00132480298634619, y = 73.8511581420898, z = 0.0061590364202857}"] =
    "position = {x = 21.285824, y = 1.553193, z = -3.878905}\\nrotation = {x = -0.0013, y = 73.8512, z = 0.0062}",
  ["position = {x = 19.8650665283203, y = 1.62497305870056, z = -6.56479787826538}\\nrotation = {x = 355.444213867188, y = 74.9148483276367, z = 0.825601100921631}"] =
    "position = {x = 20.319544, y = 1.625034, z = -6.946516}\\nrotation = {x = 355.4442, y = 74.9148, z = 0.8256}",
  ["position = {x = 23.3513240814209, y = 1.55317950248718, z = -2.63343906402588}\\nrotation = {x = 359.993957519531, y = 134.990036010742, z = 0.00183510512579232}"] =
    "position = {x = 23.805801, y = 1.553240, z = -3.015157}\\nrotation = {x = 359.9940, y = 134.9900, z = 0.0018}",
  ["position = {x = -3.53373503684998, y = 0.439999997615814, z = 2.38492488861084}\\nrotation = {x = 359.414123535156, y = 18.7307720184326, z = 285.203430175781}"] =
    "position = {x = -3.674124, y = 0.549131, z = 0.506719}\\nrotation = {x = 1.6468, y = 10.5077, z = 285.1271}",
  ["position = {x = 38.2059555053711, y = 1.45003998279572, z = 1.96833455562592}\\nrotation = {x = 4.58122849522624E-05, y = 292.828125, z = -0.000319893093546852}"] =
    "position = {x = 38.194954, y = 1.450048, z = 0.284218}\\nrotation = {x = 0.0000, y = 292.8281, z = -0.0003}",
  ["position = {x = 10.1193771362305, y = 0.981160223484039, z = -9.20792770385742}\\nrotation = {x = 271.520324707031, y = 359.666748046875, z = 13.1105346679688}"] =
    "position = {x = 11.667446, y = 0.983588, z = -9.290407}\\nrotation = {x = 271.5203, y = 359.6667, z = 13.1105}",
  ["position = {x = 13.7231206893921, y = -0.17586325109005, z = 3.7314076423645}\\nrotation = {x = 85.0051116943359, y = 183.140441894531, z = 117.545974731445}"] =
    "position = {x = 13.774680, y = -0.246249, z = 4.535136}\\nrotation = {x = 85.0051, y = 183.1404, z = 117.5460}",
  ["position = {x = -12.8207902908325, y = 1.45516228675842, z = -9.12396430969238}\\nrotation = {x = 0.13163897395134, y = 255.000411987305, z = 359.964080810547}"] =
    "position = {x = -11.163593, y = 1.455104, z = -7.148163}\\nrotation = {x = 0.1316, y = 255.0004, z = 359.9641}",
  ["position = {x = -16.0913352966309, y = 1.44384241104126, z = 3.7061984539032}\\nrotation = {x = 359.979766845703, y = 240.001708984375, z = 359.986053466797}"] =
    "position = {x = -15.980996, y = 1.443592, z = 3.266973}\\nrotation = {x = 359.9798, y = 240.0017, z = 359.9861}",
  ["position = {x = 26.631420135498, y = 0.685705482959747, z = -10.2661724090576}\\nrotation = {x = 0.0318488031625748, y = 143.140502929688, z = 359.989196777344}"] =
    "position = {x = 28.209223, y = 0.685182, z = -10.688231}\\nrotation = {x = 0.0318, y = 143.1405, z = 359.9892}",
  ["position = {x = 19.3428516387939, y = 1.44575369358063, z = -11.4030704498291}\\nrotation = {x = 359.986206054688, y = 161.867279052734, z = 359.971984863281}"] =
    "position = {x = 19.814280, y = 1.445837, z = -11.953796}\\nrotation = {x = 359.9862, y = 161.8673, z = 359.9720}",
  ["position = {x = 9.94949150085449, y = 1.44396615028381, z = -7.89880228042603}\\nrotation = {x = 359.983367919922, y = 75.0171508789063, z = 359.977966308594}"] =
    "position = {x = 11.497561, y = 1.446395, z = -7.981281}\\nrotation = {x = 359.9834, y = 75.0172, z = 359.9780}",
  ["position = {x = 11.9297008514404, y = 1.44329380989075, z = 4.72188520431519}\\nrotation = {x = 0.0513981766998768, y = 29.9797801971436, z = 359.988739013672}"] =
    "position = {x = 12.593338, y = 1.442226, z = 5.689768}\\nrotation = {x = 0.0514, y = 29.9798, z = 359.9887}",
  ["position = {x = -12.7126169204712, y = 1.44450974464417, z = 5.40597152709961}\\nrotation = {x = 359.963684082031, y = 322.395233154297, z = -0.00408841483294964}"] =
    "position = {x = -12.602283, y = 1.444259, z = 4.966745}\\nrotation = {x = 359.9637, y = 322.3952, z = -0.0041}",
  ["position = {x = 40.2920379638672, y = 1.01451730728149, z = 0.443526446819305}\\nrotation = {x = 359.8828125, y = 134.266571044922, z = 0.0211584400385618}"] =
    "position = {x = 40.261086, y = 1.014525, z = -1.256454}\\nrotation = {x = 359.8828, y = 134.2666, z = 0.0212}",
  -- competitive-jedha-city-center
  ["position = {x = 24.0311870574951, y = 1.43987047672272, z = -12.15234375}\\nrotation = {x = 0.000802320486400276, y = 59.9957389831543, z = 0.00139816047158092}"] =
    "position = {x = 23.940813, y = 1.439847, z = -11.308809}\\nrotation = {x = 0.0008, y = 59.9957, z = 0.0014}",
  ["position = {x = -7.10643577575684, y = 1.43984413146973, z = -11.2100524902344}\\nrotation = {x = -0.00138910498935729, y = 150.005264282227, z = 0.000809831079095602}"] =
    "position = {x = -8.074862, y = 1.439844, z = -11.180942}\\nrotation = {x = -0.0014, y = 150.0053, z = 0.0008}",
  ["position = {x = 8.22289657592773, y = 1.43987011909485, z = -12.1387786865234}\\nrotation = {x = 0.00155057676602155, y = 15.0209150314331, z = 0.000419494113884866}"] =
    "position = {x = 6.693122, y = 1.439858, z = -11.728278}\\nrotation = {x = 0.0016, y = 15.0209, z = 0.0004}",
  ["position = {x = 24.4888687133789, y = 1.43240177631378, z = -3.36489701271057}\\nrotation = {x = 0.00139205495361239, y = 29.8629131317139, z = 0.000799214583821595}"] =
    "position = {x = 24.304768, y = 1.432400, z = -3.303106}\\nrotation = {x = 0.0014, y = 29.8629, z = 0.0008}",
  ["position = {x = 13.7087955474854, y = 1.43395066261292, z = 8.5728759765625}\\nrotation = {x = -0.000802403083071113, y = 120.008842468262, z = 0.0013903776416555}"] =
    "position = {x = 14.126771, y = 1.433957, z = 8.331472}\\nrotation = {x = -0.0008, y = 120.0088, z = 0.0014}",
  ["position = {x = 27.6770000457764, y = -0.0641121044754982, z = -5.49594831466675}\\nrotation = {x = -0.000803341798018664, y = 120.012268066406, z = 0.00139072583988309}"] =
    "position = {x = 26.536753, y = -0.064129, z = -4.881682}\\nrotation = {x = -0.0008, y = 120.0123, z = 0.0014}",
  ["position = {x = 1.80096101760864, y = 1.43419170379639, z = 9.76803398132324}\\nrotation = {x = -0.000935085990931839, y = 120.002098083496, z = 0.00118696654681116}"] =
    "position = {x = 1.959034, y = 1.434218, z = 10.041804}\\nrotation = {x = -0.0009, y = 120.0021, z = 0.0012}",
  ["position = {x = 11.5719232559204, y = 2.42465996742249, z = 5.38130187988281}\\nrotation = {x = -0.00133593054488301, y = 210.103942871094, z = -0.000747298239730299}"] =
    "position = {x = 12.020291, y = 2.424667, z = 5.121266}\\nrotation = {x = -0.0013, y = 210.1039, z = -0.0007}",
  ["position = {x = 1.77353775501251, y = 1.43014669418335, z = 9.76931285858154}\\nrotation = {x = 0.00414352351799607, y = 120.001739501953, z = -0.00358774326741695}"] =
    "position = {x = 1.931611, y = 1.430173, z = 10.043083}\\nrotation = {x = 0.0041, y = 120.0017, z = -0.0036}",
  ["position = {x = 20.2420310974121, y = 1.43451011180878, z = -1.37087786197662}\\nrotation = {x = 0.000808923039585352, y = 300.128295898438, z = -0.00137331301812083}"] =
    "position = {x = 20.107157, y = 1.434509, z = -1.337354}\\nrotation = {x = 0.0008, y = 300.1283, z = -0.0014}",
  ["position = {x = 27.6797771453857, y = 2.44261717796326, z = -5.50466728210449}\\nrotation = {x = -0.000257224222877994, y = 120.005348205566, z = 0.0014909413876012}"] =
    "position = {x = 26.539530, y = 2.442597, z = -4.890401}\\nrotation = {x = -0.0003, y = 120.0053, z = 0.0015}",
  ["position = {x = 20.2126636505127, y = 1.43070983886719, z = -1.36647856235504}\\nrotation = {x = 0.000831062556244433, y = 299.97265625, z = -0.00142293318640441}"] =
    "position = {x = 20.077789, y = 1.430709, z = -1.332954}\\nrotation = {x = 0.0008, y = 299.9727, z = -0.0014}",
  ["position = {x = 11.5586538314819, y = 2.43229532241821, z = 5.38156890869141}\\nrotation = {x = -0.000792251958046108, y = 210.118621826172, z = -0.000702974444720894}"] =
    "position = {x = 12.007022, y = 2.432303, z = 5.121533}\\nrotation = {x = -0.0008, y = 210.1186, z = -0.0007}",
  ["position = {x = 1.80945026874542, y = 1.43330311775208, z = 9.78528785705566}\\nrotation = {x = 0.00245907949283719, y = 120.001838684082, z = -0.00461234897375107}"] =
    "position = {x = 1.967524, y = 1.433329, z = 10.059058}\\nrotation = {x = 0.0025, y = 120.0018, z = -0.0046}",
  ["position = {x = 27.6757659912109, y = 2.44595241546631, z = -5.49988842010498}\\nrotation = {x = -0.000744692282751203, y = 120.012268066406, z = 0.00143291905988008}"] =
    "position = {x = 26.535519, y = 2.445933, z = -4.885622}\\nrotation = {x = -0.0007, y = 120.0123, z = 0.0014}",
  ["position = {x = 11.5777778625488, y = -0.0899836197495461, z = 5.37668895721436}\\nrotation = {x = -0.00133593054488301, y = 210.103942871094, z = -0.000747298239730299}"] =
    "position = {x = 12.026145, y = -0.089977, z = 5.116653}\\nrotation = {x = -0.0013, y = 210.1039, z = -0.0007}",
  ["position = {x = 20.2160568237305, y = 1.43382978439331, z = -1.37642133235931}\\nrotation = {x = 0.000731772917788476, y = 299.997680664063, z = -0.00142313807737082}"] =
    "position = {x = 20.081182, y = 1.433829, z = -1.342897}\\nrotation = {x = 0.0007, y = 299.9977, z = -0.0014}",
  ["position = {x = 41.0310554504395, y = 1.4383579492569, z = 7.78672456741333}\\nrotation = {x = -0.000807401083875448, y = 119.986862182617, z = 0.0013903568033129}"] =
    "position = {x = 41.140877, y = 1.438345, z = 8.251293}\\nrotation = {x = -0.0008, y = 119.9869, z = 0.0014}",
  ["position = {x = 21.5051174163818, y = 1.43851518630981, z = 2.17331504821777}\\nrotation = {x = -0.000806010386440903, y = 120.009635925293, z = 0.0013899045297876}"] =
    "position = {x = 21.370243, y = 1.438514, z = 2.206839}\\nrotation = {x = -0.0008, y = 120.0096, z = 0.0014}",
  ["position = {x = -8.76568031311035, y = 1.4381742477417, z = 14.3464517593384}\\nrotation = {x = 0.000811178353615105, y = 300.025848388672, z = -0.0013907611137256}"] =
    "position = {x = -8.582661, y = 1.438165, z = 14.663117}\\nrotation = {x = 0.0008, y = 300.0258, z = -0.0014}",
  ["position = {x = -1.24253392219543, y = -0.442725777626038, z = 7.08286428451538}\\nrotation = {x = 0.00138057954609394, y = 30.9416446685791, z = 0.000827153271529824}"] =
    "position = {x = -1.009337, y = -0.442737, z = 7.471865}\\nrotation = {x = 0.0014, y = 30.9416, z = 0.0008}",
  ["position = {x = -0.0629105642437935, y = 1.43757569789886, z = -6.62558174133301}\\nrotation = {x = 0.000812332611531019, y = 299.982849121094, z = -0.00138913188129663}"] =
    "position = {x = -0.354228, y = 1.437590, z = -7.130508}\\nrotation = {x = 0.0008, y = 299.9828, z = -0.0014}",
  ["position = {x = 32.2387237548828, y = 1.43752181529999, z = -4.693932056427}\\nrotation = {x = 0.000780292029958218, y = 298.924194335938, z = -0.00140476366505027}"] =
    "position = {x = 31.418390, y = 1.437509, z = -4.240629}\\nrotation = {x = 0.0008, y = 298.9242, z = -0.0014}",
  ["position = {x = 36.2798500061035, y = 1.44497013092041, z = 8.52743530273438}\\nrotation = {x = 0.000802733993623406, y = 300.005798339844, z = -0.00139072770252824}"] =
    "position = {x = 36.389671, y = 1.444957, z = 8.992004}\\nrotation = {x = 0.0008, y = 300.0058, z = -0.0014}",
  ["position = {x = 31.6080074310303, y = 1.43558502197266, z = 13.9757251739502}\\nrotation = {x = -0.00139268930070102, y = 210.005859375, z = -0.000801507034339011}"] =
    "position = {x = 31.717829, y = 1.435572, z = 14.440294}\\nrotation = {x = -0.0014, y = 210.0059, z = -0.0008}",
  ["position = {x = 41.6595687866211, y = 1.44598031044006, z = 5.45546913146973}\\nrotation = {x = -0.000790193153079599, y = 120.005867004395, z = 0.0012965255882591}"] =
    "position = {x = 41.769390, y = 1.445967, z = 5.920038}\\nrotation = {x = -0.0008, y = 120.0059, z = 0.0013}",
  ["position = {x = 5.04270172119141, y = 1.44196820259094, z = -6.51427221298218}\\nrotation = {x = 0.00148392154369503, y = 29.9872493743896, z = 0.00081026233965531}"] =
    "position = {x = 4.544556, y = 1.441983, z = -6.989021}\\nrotation = {x = 0.0015, y = 29.9872, z = 0.0008}",
  ["position = {x = 4.90923404693604, y = 1.43561315536499, z = -6.77811479568481}\\nrotation = {x = -0.00138978299219161, y = 210.049835205078, z = -0.000805273535661399}"] =
    "position = {x = 4.430117, y = 1.435626, z = -7.219784}\\nrotation = {x = -0.0014, y = 210.0498, z = -0.0008}",
  ["position = {x = 5.06369066238403, y = 1.43560945987701, z = -6.48760795593262}\\nrotation = {x = 0.0013929643901065, y = 29.9842376708984, z = 0.00080397049896419}"] =
    "position = {x = 4.574917, y = 1.435623, z = -6.946127}\\nrotation = {x = 0.0014, y = 29.9842, z = 0.0008}",
  ["position = {x = 9.63912677764893, y = 0.881711184978485, z = 2.79719090461731}\\nrotation = {x = 0.00194317754358053, y = 30.0329971313477, z = 0.000117082039650995}"] =
    "position = {x = 9.828028, y = 0.881714, z = 2.687672}\\nrotation = {x = 0.0019, y = 30.0330, z = 0.0001}",
  ["position = {x = 30.3118076324463, y = 0.753521084785461, z = -7.44220638275146}\\nrotation = {x = 0.000806686235591769, y = 300.004486083984, z = -0.00141012389212847}"] =
    "position = {x = 29.171560, y = 0.753504, z = -6.827940}\\nrotation = {x = 0.0008, y = 300.0045, z = -0.0014}",
  ["position = {x = 1.75853979587555, y = 1.43399930000305, z = -4.76370143890381}\\nrotation = {x = 0.00140376703348011, y = 30.0057697296143, z = 0.00080755865201354}"] =
    "position = {x = 1.260391, y = 1.434014, z = -5.238450}\\nrotation = {x = 0.0014, y = 30.0058, z = 0.0008}",
  ["position = {x = 8.22965621948242, y = 1.43410515785217, z = -8.51158428192139}\\nrotation = {x = -0.00139560375828296, y = 209.994201660156, z = -0.000805208110250533}"] =
    "position = {x = 7.731501, y = 1.434120, z = -8.986336}\\nrotation = {x = -0.0014, y = 209.9942, z = -0.0008}",
  ["position = {x = -22.4841270446777, y = 1.43517243862152, z = 4.16037034988403}\\nrotation = {x = -0.0011433936888352, y = 135.429458618164, z = 0.00112708553206176}"] =
    "position = {x = -23.114710, y = 1.435151, z = 4.930665}\\nrotation = {x = -0.0011, y = 135.4295, z = 0.0011}",
  ["position = {x = -20.6747055053711, y = 0.270412087440491, z = 1.20301127433777}\\nrotation = {x = 350.364837646484, y = 138.276138305664, z = 15.378475189209}"] =
    "position = {x = -21.297838, y = 0.270388, z = 2.062997}\\nrotation = {x = 350.3648, y = 138.2761, z = 15.3785}",
  ["position = {x = -20.9461669921875, y = 1.36041152477264, z = -0.323492854833603}\\nrotation = {x = 0.00150389119517058, y = 20.468376159668, z = 0.000561475637368858}"] =
    "position = {x = -21.569300, y = 1.360388, z = 0.536493}\\nrotation = {x = 0.0015, y = 20.4684, z = 0.0006}",
  ["position = {x = -5.03419589996338, y = 1.43956768512726, z = -16.2303161621094}\\nrotation = {x = 0.0229206010699272, y = 359.991485595703, z = 0.02130495198071}"] =
    "position = {x = -6.002625, y = 1.439568, z = -16.201199}\\nrotation = {x = 0.0229, y = 359.9915, z = 0.0213}",
  ["position = {x = 16.8285064697266, y = 1.42843973636627, z = 13.5028305053711}\\nrotation = {x = 0.000798052875325084, y = 299.994140625, z = -0.00139030767604709}"] =
    "position = {x = 18.084953, y = 1.428459, z = 12.777589}\\nrotation = {x = 0.0008, y = 299.9941, z = -0.0014}",
  -- competitive-scarif-landing
  ["position = {x = -8.54680824279785, y = 1.43015372753143, z = -5.30739307403564}\\nrotation = {x = -0.00159981974866241, y = 179.999938964844, z = -4.15277895626787E-07}"] =
    "position = {x = -8.695042, y = 1.430149, z = -5.176297}\\nrotation = {x = -0.0015, y = 200.3294, z = -0.0006}",
  ["position = {x = 7.83302021026611, y = 1.4362096786499, z = -0.148133277893066}\\nrotation = {x = 0.00100798439234495, y = 359.703552246094, z = -0.00128115818370134}"] =
    "position = {x = 7.831464, y = 1.436205, z = 0.152718}\\nrotation = {x = 0.0010, y = 359.7036, z = -0.0013}",
  ["position = {x = 26.0264720916748, y = 1.43000292778015, z = 0.326651513576508}\\nrotation = {x = -0.0015973795671016, y = 180.011901855469, z = 2.68568840056105E-07}"] =
    "position = {x = 25.916515, y = 1.430010, z = 0.050161}\\nrotation = {x = -0.0016, y = 180.0119, z = 0.0000}",
  ["position = {x = -10.2600021362305, y = 1.42999863624573, z = 0.481934666633606}\\nrotation = {x = -0.00159379735123366, y = 180.008361816406, z = -7.01851149642607E-07}"] =
    "position = {x = -9.858260, y = 1.430011, z = 0.027372}\\nrotation = {x = -0.0016, y = 180.0084, z = 0.0000}",
  ["position = {x = 15.7835741043091, y = 1.41870927810669, z = -5.42613649368286}\\nrotation = {x = -0.00136659224517643, y = 150.000289916992, z = 0.00056232133647427}"] =
    "position = {x = 15.783574, y = 1.407300, z = -5.426136}\\nrotation = {x = -0.0014, y = 150.0003, z = 0.0006}",
  ["position = {x = -20.8008117675781, y = 1.40432977676392, z = -2.03566527366638}\\nrotation = {x = 0.00153004890307784, y = 14.9818429946899, z = 0.000645188090857118}"] =
    "position = {x = -20.800812, y = 1.375300, z = -2.035665}\\nrotation = {x = 0.0015, y = 14.9818, z = 0.0006}",
  ["position = {x = 25.4263496398926, y = 1.41932904720306, z = -7.13631963729858}\\nrotation = {x = 0.00153951707761735, y = 14.9827136993408, z = 0.000411511195125058}"] =
    "position = {x = 25.426350, y = 1.397900, z = -7.136320}\\nrotation = {x = 0.0015, y = 14.9827, z = 0.0004}",
  ["position = {x = 32.8279113769531, y = 1.40999972820282, z = -0.331467509269714}\\nrotation = {x = 0.0015401536365971, y = 15.017219543457, z = 0.000413132482208312}"] =
    "position = {x = 32.827911, y = 1.388100, z = -0.331468}\\nrotation = {x = 0.0015, y = 15.0172, z = 0.0004}",
  ["position = {x = 7.86741542816162, y = 1.41605758666992, z = -12.7399005889893}\\nrotation = {x = 0.00153815455269068, y = 15.0215358734131, z = 0.000413463596487418}"] =
    "position = {x = 7.867415, y = 1.391400, z = -12.739901}\\nrotation = {x = 0.0015, y = 15.0215, z = 0.0004}",
  ["position = {x = -16.9460487365723, y = 1.57156324386597, z = -1.69910323619843}\\nrotation = {x = 0.444782108068466, y = 14.9955539703369, z = 358.556976318359}"] =
    "position = {x = -16.946049, y = 1.500200, z = -1.699103}\\nrotation = {x = 0.4448, y = 14.9956, z = 358.5570}",
  ["position = {x = 33.3030395507813, y = 1.41940951347351, z = -10.0228672027588}\\nrotation = {x = 0.00153933383990079, y = 14.9992647171021, z = 0.000412721565226093}"] =
    "position = {x = 33.303040, y = 1.401800, z = -10.022867}\\nrotation = {x = 0.0015, y = 14.9993, z = 0.0004}",
  ["position = {x = -25.8519859313965, y = 1.41858386993408, z = -0.8843994140625}\\nrotation = {x = 0.00154278159607202, y = 14.9981269836426, z = 0.000413580040913075}"] =
    "position = {x = -25.851986, y = 1.405600, z = -0.884399}\\nrotation = {x = 0.0015, y = 14.9981, z = 0.0004}",
  ["position = {x = 28.7779579162598, y = 1.41026544570923, z = -9.87443161010742}\\nrotation = {x = 0.00153931637760252, y = 15.0172472000122, z = 0.000413263071095571}"] =
    "position = {x = 28.777958, y = 1.392200, z = -9.874432}\\nrotation = {x = 0.0015, y = 15.0172, z = 0.0004}",
  ["position = {x = -16.9946060180664, y = 1.41870045661926, z = -5.07759714126587}\\nrotation = {x = 0.00154124677646905, y = 14.9978475570679, z = 0.000411343818996102}"] =
    "position = {x = -16.994606, y = 1.393500, z = -5.077597}\\nrotation = {x = 0.0015, y = 14.9978, z = 0.0004}",
  ["position = {x = -14.140100479126, y = 1.41858243942261, z = -0.805441737174988}\\nrotation = {x = 0.00154551828745753, y = 15.0087175369263, z = 0.000387586973374709}"] =
    "position = {x = -14.140100, y = 1.390600, z = -0.805442}\\nrotation = {x = 0.0015, y = 15.0087, z = 0.0004}",
  -- competitive-tatooine-scum-and-villainy
  ["position = {x = -19.6254119873047, y = 1.44134545326233, z = -5.48735189437866}\\nrotation = {x = -0.000803306291345507, y = 300.024627685547, z = 0.00139014550950378}"] =
    "position = {x = -19.338371, y = 1.441339, z = -5.695487}\\nrotation = {x = -0.0008, y = 300.0246, z = 0.0014}",
  ["position = {x = -7.77651262283325, y = 1.44112384319305, z = -13.225830078125}\\nrotation = {x = 359.978698730469, y = 254.976470947266, z = 359.929412841797}"] =
    "position = {x = -8.812684, y = 1.440928, z = -13.798003}\\nrotation = {x = 359.9787, y = 254.9765, z = 359.9294}",
  ["position = {x = 8.73725318908691, y = 1.44186174869537, z = 13.168963432312}\\nrotation = {x = 359.979461669922, y = 224.980361938477, z = 359.929290771484}"] =
    "position = {x = 8.074819, y = 1.440074, z = 14.392470}\\nrotation = {x = 359.9795, y = 224.9804, z = 359.9293}",
  ["position = {x = 9.52595329284668, y = 1.44150459766388, z = 0.430445075035095}\\nrotation = {x = 359.976928710938, y = 329.987213134766, z = 359.929016113281}"] =
    "position = {x = 9.614139, y = 1.441378, z = 0.481385}\\nrotation = {x = 359.9769, y = 329.9872, z = 359.9290}",
  ["position = {x = -5.20824480056763, y = 1.44147384166718, z = -11.7628765106201}\\nrotation = {x = 0.0124622276052833, y = 225.022872924805, z = 0.0395650155842304}"] =
    "position = {x = -6.383098, y = 1.441473, z = -12.377584}\\nrotation = {x = 0.0125, y = 225.0229, z = 0.0396}",
  ["position = {x = -21.6127738952637, y = -1.46010518074036, z = 11.9319486618042}\\nrotation = {x = -0.0011388473212719, y = 44.99169921875, z = -0.00113686814438552}"] =
    "position = {x = -22.344217, y = -1.460095, z = 12.312418}\\nrotation = {x = -0.0011, y = 44.9917, z = -0.0011}",
  ["position = {x = 26.5346508026123, y = -1.46061432361603, z = -6.25960350036621}\\nrotation = {x = 0.000813075399491936, y = 120.020095825195, z = -0.00138851150404662}"] =
    "position = {x = 26.852901, y = -1.460582, z = -5.102333}\\nrotation = {x = 0.0008, y = 120.0201, z = -0.0014}",
  ["position = {x = 30.0200614929199, y = -0.30014443397522, z = -5.27683210372925}\\nrotation = {x = 0.00139285495970398, y = 209.988174438477, z = 0.000803171948064119}"] =
    "position = {x = 30.338312, y = -0.300112, z = -4.119562}\\nrotation = {x = 0.0014, y = 209.9882, z = 0.0008}",
  ["position = {x = 18.8397903442383, y = -0.299712896347046, z = 10.1442852020264}\\nrotation = {x = -0.000805053627118468, y = 300.022094726563, z = 0.00138921814505011}"] =
    "position = {x = 16.243830, y = -0.299695, z = 10.792540}\\nrotation = {x = -0.0008, y = 300.0221, z = 0.0014}",
  ["position = {x = 0.306647181510925, y = -0.299948394298553, z = 1.72354471683502}\\nrotation = {x = 0.000966672494541854, y = 126.819046020508, z = -0.0012784629361704}"] =
    "position = {x = -0.610358, y = -0.299814, z = 6.523867}\\nrotation = {x = 0.0010, y = 126.8190, z = -0.0013}",
  ["position = {x = 8.98191165924072, y = -0.300195187330246, z = -7.07858324050903}\\nrotation = {x = 0.00140330649446696, y = 210.008071899414, z = 0.000803516362793744}"] =
    "position = {x = 9.409381, y = -0.300234, z = -8.446059}\\nrotation = {x = 0.0014, y = 210.0081, z = 0.0008}",
  ["position = {x = 38.9030914306641, y = -0.300294697284698, z = -10.6115808486938}\\nrotation = {x = 0.00155504059512168, y = 165.006210327148, z = -0.000414352398365736}"] =
    "position = {x = 38.951393, y = -0.300297, z = -10.687057}\\nrotation = {x = 0.0016, y = 165.0062, z = -0.0004}",
  ["position = {x = 30.3683624267578, y = -1.46037590503693, z = 2.28214049339294}\\nrotation = {x = -0.000805038958787918, y = 299.981018066406, z = 0.00139098276849836}"] =
    "position = {x = 30.308584, y = -1.460338, z = 3.632851}\\nrotation = {x = -0.0008, y = 299.9810, z = 0.0014}",
  ["position = {x = 41.1222152709961, y = -0.442791819572449, z = -9.446457862854}\\nrotation = {x = 0.00155367504339665, y = 195.01106262207, z = 0.000415277609135956}"] =
    "position = {x = 41.170517, y = -0.442794, z = -9.521934}\\nrotation = {x = 0.0016, y = 195.0111, z = 0.0004}",
  ["position = {x = -10.1240539550781, y = -0.299848139286041, z = 3.9448983669281}\\nrotation = {x = 0.0073751169256866, y = 120.021957397461, z = -0.000659285229630768}"] =
    "position = {x = -12.508403, y = -0.299575, z = 4.227987}\\nrotation = {x = 0.0074, y = 120.0220, z = -0.0007}",
  ["position = {x = -17.5534915924072, y = -1.46024584770203, z = 6.93080520629883}\\nrotation = {x = -0.000795072002802044, y = 300.004058837891, z = 0.00139205728191882}"] =
    "position = {x = -19.937836, y = -1.459972, z = 7.213893}\\nrotation = {x = -0.0008, y = 300.0041, z = 0.0014}",
  ["position = {x = -18.3287906646729, y = -0.442378640174866, z = 5.27513408660889}\\nrotation = {x = 0.00139223993755877, y = 209.974472045898, z = 0.00080227613216266}"] =
    "position = {x = -20.713135, y = -0.442106, z = 5.558222}\\nrotation = {x = 0.0014, y = 209.9745, z = 0.0008}",
  ["position = {x = 1.25170755386353, y = -1.4603590965271, z = 2.8809015750885}\\nrotation = {x = 0.00139862054493278, y = 209.980758666992, z = 0.000792022736277431}"] =
    "position = {x = 0.141708, y = -1.460224, z = 7.727287}\\nrotation = {x = 0.0014, y = 209.9808, z = 0.0008}",
  ["position = {x = 38.8963661193848, y = -1.46071422100067, z = -9.73699188232422}\\nrotation = {x = -0.00155585142783821, y = 345.002716064453, z = 0.000414143549278378}"] =
    "position = {x = 38.944668, y = -1.460715, z = -9.812468}\\nrotation = {x = -0.0016, y = 345.0027, z = 0.0004}",
  ["position = {x = -6.68332958221436, y = -1.46050548553467, z = -2.30993366241455}\\nrotation = {x = -0.000804059149231762, y = 300.01220703125, z = 0.00138996040914208}"] =
    "position = {x = -7.059552, y = -1.460524, z = -2.961251}\\nrotation = {x = -0.0008, y = 300.0122, z = 0.0014}",
  ["position = {x = 8.94188976287842, y = -1.46068859100342, z = -8.88713455200195}\\nrotation = {x = 0.00080578331835568, y = 120.01016998291, z = -0.00139071873854846}"] =
    "position = {x = 10.641949, y = -1.460698, z = -9.233176}\\nrotation = {x = 0.0008, y = 120.0102, z = -0.0014}",
  ["position = {x = 18.6489906311035, y = 2.00361752510071, z = -5.10643720626831}\\nrotation = {x = -0.00138438888825476, y = 29.9937267303467, z = -0.000805211835540831}"] =
    "position = {x = 16.800198, y = 2.003408, z = -3.662510}\\nrotation = {x = -0.0014, y = 29.9937, z = -0.0008}",
  ["position = {x = -8.42454719543457, y = -0.442442208528519, z = 3.89519453048706}\\nrotation = {x = 0.0012181120691821, y = 195.001083374023, z = -0.00174895871896297}"] =
    "position = {x = -10.808896, y = -0.442169, z = 4.178282}\\nrotation = {x = 0.0012, y = 195.0011, z = -0.0017}",
  ["position = {x = 34.1596336364746, y = -0.299896121025085, z = 3.59587287902832}\\nrotation = {x = 0.000787484634201974, y = 119.902198791504, z = -0.00140342314261943}"] =
    "position = {x = 34.099846, y = -0.299858, z = 4.946583}\\nrotation = {x = 0.0008, y = 119.9022, z = -0.0014}",
  ["position = {x = 17.3246440887451, y = 0.450867027044296, z = -3.53446984291077}\\nrotation = {x = 359.957427978516, y = 210.023162841797, z = 359.979431152344}"] =
    "position = {x = 15.475857, y = 0.450657, z = -2.090544}\\nrotation = {x = 359.9574, y = 210.0232, z = 359.9794}",
  ["position = {x = -20.1504573822021, y = -1.46015048027039, z = 10.3318290710449}\\nrotation = {x = -0.00113936327397823, y = 315.016662597656, z = 0.00113440374843776}"] =
    "position = {x = -21.281477, y = -1.460130, z = 11.112101}\\nrotation = {x = -0.0011, y = 315.0167, z = 0.0011}",
  ["position = {x = 27.9425868988037, y = 2.00359034538269, z = -6.06765937805176}\\nrotation = {x = 0.000837206549476832, y = 119.947601318359, z = -0.00139107031282038}"] =
    "position = {x = 28.260838, y = 2.003624, z = -4.910388}\\nrotation = {x = 0.0008, y = 119.9476, z = -0.0014}",
  ["position = {x = -20.5889072418213, y = 0.870232582092285, z = 10.8938694000244}\\nrotation = {x = -0.00208927085623145, y = 29.980016708374, z = -0.00303565384820104}"] =
    "position = {x = -21.320351, y = 0.870244, z = 11.274340}\\nrotation = {x = -0.0021, y = 29.9800, z = -0.0030}",
  ["position = {x = 34.4325714111328, y = -0.638073205947876, z = 2.8471519947052}\\nrotation = {x = -0.00140627741347998, y = 29.3405094146729, z = -0.000743467127904296}"] =
    "position = {x = 34.372780, y = -0.638036, z = 4.197862}\\nrotation = {x = -0.0014, y = 29.3405, z = -0.0007}",
  ["position = {x = 29.4978713989258, y = -0.442426264286041, z = 3.59073328971863}\\nrotation = {x = 0.00139064027462155, y = 210.009582519531, z = 0.000803513277787715}"] =
    "position = {x = 29.438093, y = -0.442389, z = 4.941444}\\nrotation = {x = 0.0014, y = 210.0096, z = 0.0008}",
  ["position = {x = -9.64798831939697, y = -0.517088770866394, z = 3.53580856323242}\\nrotation = {x = -0.00160479277838022, y = 29.6086730957031, z = 359.994232177734}"] =
    "position = {x = -12.032337, y = -0.516815, z = 3.818896}\\nrotation = {x = -0.0016, y = 29.6087, z = 359.9942}",
  ["position = {x = 34.8805961608887, y = -0.442477941513062, z = 1.75277054309845}\\nrotation = {x = -0.00139099336229265, y = 30.586540222168, z = -0.000823730835691094}"] =
    "position = {x = 34.820808, y = -0.442440, z = 3.103481}\\nrotation = {x = -0.0014, y = 30.5865, z = -0.0008}",
  ["position = {x = 20.1472396850586, y = -1.46013879776001, z = 10.7312650680542}\\nrotation = {x = -0.000831385725177825, y = 300.025970458984, z = 0.00138853408861905}"] =
    "position = {x = 21.299519, y = -1.460145, z = 10.557445}\\nrotation = {x = -0.0008, y = 300.0260, z = 0.0014}",
  ["position = {x = -13.0574398040771, y = 1.63745272159576, z = -6.58421611785889}\\nrotation = {x = -0.000749876548070461, y = 30.0053558349609, z = 0.00632969476282597}"] =
    "position = {x = -14.319347, y = 1.637420, z = -8.769433}\\nrotation = {x = -0.0007, y = 30.0054, z = 0.0063}",
  ["position = {x = -14.8000001907349, y = 1.44132852554321, z = -7.46000003814697}\\nrotation = {x = 0.000803511240519583, y = 120.014488220215, z = -0.00139007484540343}"] =
    "position = {x = -15.923445, y = 1.441258, z = -9.991001}\\nrotation = {x = 0.0008, y = 120.0145, z = -0.0014}",
  ["position = {x = 3.27032947540283, y = 1.44174361228943, z = 6.19128799438477}\\nrotation = {x = 0.000802450813353062, y = 210, z = -0.00139012234285474}"] =
    "position = {x = 2.604400, y = 1.441726, z = 10.890098}\\nrotation = {x = 0.0008, y = 210.0000, z = -0.0014}",
  ["position = {x = -18.4686317443848, y = 1.44155621528625, z = 0.891271710395813}\\nrotation = {x = 0.0045435088686645, y = 120.00952911377, z = -0.00117223837878555}"] =
    "position = {x = -18.193926, y = 1.441474, z = 0.690619}\\nrotation = {x = 0.0045, y = 120.0095, z = -0.0012}",
  ["position = {x = -13.4504613876343, y = 1.75664961338043, z = -4.04115390777588}\\nrotation = {x = -0.000700382341165096, y = 300.019958496094, z = -0.000506480981130153}"] =
    "position = {x = -14.533877, y = 1.756671, z = -6.475059}\\nrotation = {x = -0.0007, y = 300.0200, z = -0.0005}",
  ["position = {x = 34.6408615112305, y = 1.25822687149048, z = -2.83336663246155}\\nrotation = {x = -0.00115801696665585, y = 30.0000190734863, z = -0.00248665362596512}"] =
    "position = {x = 33.941841, y = 1.258249, z = -2.793515}\\nrotation = {x = -0.0012, y = 30.0000, z = -0.0025}",
  ["position = {x = -13.5194454193115, y = 2.31118679046631, z = -4.2661247253418}\\nrotation = {x = 0.000820653222035617, y = 120.018844604492, z = 180.038360595703}"] =
    "position = {x = -14.484083, y = 2.312803, z = -6.503368}\\nrotation = {x = 0.0008, y = 120.0188, z = 180.0384}",
  ["position = {x = 24.1458110809326, y = 1.25951302051544, z = 4.13886499404907}\\nrotation = {x = -0.00137895112857223, y = 29.9998607635498, z = 4.89362764358521}"] =
    "position = {x = 24.018904, y = 1.246967, z = 4.212133}\\nrotation = {x = -0.0014, y = 29.9999, z = 4.8936}",
  ["position = {x = 17.4787406921387, y = 1.44147872924805, z = -0.695677101612091}\\nrotation = {x = 0.000804625684395432, y = 120.02921295166, z = -0.00138963619247079}"] =
    "position = {x = 15.466668, y = 1.441510, z = 0.465698}\\nrotation = {x = 0.0008, y = 120.0292, z = -0.0014}",
  ["position = {x = 32.4799995422363, y = 1.44169354438782, z = -1.16999995708466}\\nrotation = {x = -0.00243970775045455, y = 300, z = 0.00144482508767396}"] =
    "position = {x = 32.420212, y = 1.441731, z = 0.180711}\\nrotation = {x = -0.0024, y = 300.0000, z = 0.0014}",
  ["position = {x = 14.0100002288818, y = 1.44118165969849, z = -7.17999982833862}\\nrotation = {x = 0.00140547228511423, y = 210, z = 0.000774147978518158}"] =
    "position = {x = 14.280326, y = 1.441195, z = -6.711782}\\nrotation = {x = 0.0014, y = 210.0000, z = 0.0008}",
  ["position = {x = -4.65000009536743, y = 1.4410697221756, z = -5.84999990463257}\\nrotation = {x = 0.000770504819229245, y = 300, z = -0.00144675944466144}"] =
    "position = {x = -5.395093, y = 1.441107, z = -7.100239}\\nrotation = {x = 0.0008, y = 300.0000, z = -0.0014}",
  ["position = {x = -13.3500003814697, y = 1.44173181056976, z = 5.86999988555908}\\nrotation = {x = -0.00139068451244384, y = 29.992015838623, z = -0.000801733054686338}"] =
    "position = {x = -15.734349, y = 1.442005, z = 6.153088}\\nrotation = {x = -0.0014, y = 29.9920, z = -0.0008}",
  ["position = {x = 20.9300003051758, y = 1.44175755977631, z = 5.80000066757202}\\nrotation = {x = -0.00138937786687166, y = 29.9879703521729, z = -0.000802182650659233}"] =
    "position = {x = 19.941748, y = 1.441770, z = 6.232558}\\nrotation = {x = -0.0014, y = 29.9880, z = -0.0008}",
  ["position = {x = 34.3241653442383, y = 1.44111287593842, z = -11.9056234359741}\\nrotation = {x = -0.000414517649915069, y = 320, z = 0.00154960690997541}"] =
    "position = {x = 34.243198, y = 1.441146, z = -10.483660}\\nrotation = {x = -0.0004, y = 320.0000, z = 0.0015}",
  ["position = {x = 11.3885192871094, y = 1.43262207508087, z = -3.20978021621704}\\nrotation = {x = 0.00155202567111701, y = 195.013931274414, z = 0.000415310962125659}"] =
    "position = {x = 11.668627, y = 1.432631, z = -2.911181}\\nrotation = {x = 0.0016, y = 195.0139, z = 0.0004}",
  ["position = {x = 27.2214317321777, y = 1.43258047103882, z = -4.70140314102173}\\nrotation = {x = -0.00125169882085174, y = 321.288848876953, z = 0.00100538844708353}"] =
    "position = {x = 27.539682, y = 1.432613, z = -3.544133}\\nrotation = {x = -0.0013, y = 321.2888, z = 0.0010}",
  ["position = {x = -18.4814643859863, y = 1.43287098407745, z = 5.67422008514404}\\nrotation = {x = -0.00113449699711055, y = 44.9768257141113, z = -0.00113251048605889}"] =
    "position = {x = -20.865808, y = 1.433144, z = 5.957308}\\nrotation = {x = -0.0011, y = 44.9768, z = -0.0011}",
  ["position = {x = -8.33991241455078, y = 1.43246448040009, z = -8.83614063262939}\\nrotation = {x = -0.000417026079958305, y = 285.001098632813, z = 0.00155225268099457}"] =
    "position = {x = -7.486488, y = 1.432519, z = -6.881277}\\nrotation = {x = -0.0004, y = 285.0011, z = 0.0016}",
  ["position = {x = -16.3728103637695, y = 1.44251763820648, z = -13.1782464981079}\\nrotation = {x = 0.00113552378024906, y = 225.001037597656, z = 0.00113456451799721}"] =
    "position = {x = -12.221650, y = 1.442510, z = -13.425306}\\nrotation = {x = 0.0011, y = 225.0010, z = 0.0011}",
  ["position = {x = -24.0747890472412, y = 1.44163000583649, z = 4.6251482963562}\\nrotation = {x = 0.000802498776465654, y = 120.01725769043, z = -0.00139086088165641}"] =
    "position = {x = -23.772799, y = 1.441622, z = 4.408550}\\nrotation = {x = 0.0008, y = 120.0173, z = -0.0014}",
  ["position = {x = -21.193920135498, y = 1.44156849384308, z = 2.45903539657593}\\nrotation = {x = 0.00139404786750674, y = 209.984817504883, z = 0.000802524329628795}"] =
    "position = {x = -20.908850, y = 1.441563, z = 2.252984}\\nrotation = {x = 0.0014, y = 209.9848, z = 0.0008}",
  ["position = {x = -22.6677169799805, y = 1.44172036647797, z = 7.93714332580566}\\nrotation = {x = 0.000837490253616124, y = 119.983924865723, z = -0.00138846843037754}"] =
    "position = {x = -22.383392, y = 1.441713, z = 7.731540}\\nrotation = {x = 0.0008, y = 119.9839, z = -0.0014}",
  ["position = {x = 34.1482543945313, y = 1.44131469726563, z = -6.58152627944946}\\nrotation = {x = -0.00139366660732776, y = 29.9891815185547, z = -0.000800620764493942}"] =
    "position = {x = 34.154907, y = 1.441346, z = -5.210126}\\nrotation = {x = -0.0014, y = 29.9892, z = -0.0008}",
  ["position = {x = -18.2955894470215, y = 1.44182145595551, z = 11.4046030044556}\\nrotation = {x = -0.000809986901003867, y = 299.996398925781, z = 0.00139769457746297}"] =
    "position = {x = -18.023851, y = 1.441822, z = 11.205385}\\nrotation = {x = -0.0008, y = 299.9964, z = 0.0014}",
  ["position = {x = -14.8018312454224, y = 1.44179832935333, z = 10.7361145019531}\\nrotation = {x = 0.00160585960838944, y = 210.021286010742, z = 0.000503297080285847}"] =
    "position = {x = -14.530088, y = 1.441799, z = 10.536898}\\nrotation = {x = 0.0016, y = 210.0213, z = 0.0005}",
}

MAP_SCALE_FIXES = {
  -- Forward Command Center [Heavy Cover]
  ["position = {x = -12.8207902908325, y = 1.45516228675842, z = -9.12396430969238}\\nrotation = {x = 0.13163897395134, y = 255.000411987305, z = 359.964080810547}"] =
    '"scaleX": 1.185744, "scaleY": 0.783856, "scaleZ": 1.185737',
}

-- One walk over the saved positions of the map. A gsub per fix would rebuild
-- the whole map text each time, and a map has up to sixty of them.
local function applyPositionFixes(text)
  local out, from, pos = {}, 1, 1
  while true do
    local first = text:find("position = {", pos, true)
    if not first then break end
    local rotation = text:find("rotation = {", first, true)
    local last = rotation and text:find("}", rotation, true)
    if not last then break end
    local key = text:sub(first, last)
    local fixed = MAP_POSITION_FIXES[key]
    if fixed then
      local head = text:sub(from, first - 1)
      local scale = MAP_SCALE_FIXES[key]
      if scale then
        -- The piece's Transform comes before its script, and is the last
        -- one before it: rewrite its three scales up to the closing brace.
        local at, look = nil, 1
        while true do
          local found = head:find('"scaleX":', look, true)
          if not found then break end
          at, look = found, found + 1
        end
        local close = at and head:find("}", at, true)
        if close then
          head = head:sub(1, at - 1) .. scale .. "\n" .. head:sub(close)
        end
      end
      table.insert(out, head)
      table.insert(out, fixed)
      from, pos = last + 1, last + 1
    else
      pos = first + 1
    end
  end
  if from == 1 then return text end
  table.insert(out, text:sub(from))
  return table.concat(out)
end

function repairDeadSteamHost(text)
  local repaired = text:gsub("https?://cloud%-3%.steamusercontent%.com/", "https://steamusercontent-a.akamaihd.net/")
  repaired = applySwaps(repaired, DEAD_UGC_SWAPS)
  repaired = applyTerrainColliders(repaired)
  repaired = applyPositionFixes(repaired)
  repaired = applySwaps(repaired, MIRRORED_ASSETS, ASSET_STORE)
  return repaired
end

function downloadMapByUrl(url)
  WebRequest.get(repairDeadSteamHost(url), function(data)
    -- Read data.text now: TTS drops the download handler as soon as we yield.
    unpackMap(data.text)
  end)
end

-- Walk back from an anchor over the handful of characters of whitespace and
-- punctuation that separate two JSON tokens. Bounded on purpose: if the file
-- is not shaped as expected we give up and the caller falls back to decoding.
function lastCharBefore(text, char, limit)
  local floor = math.max(1, limit - 200)
  for i = limit - 1, floor, -1 do
    if text:sub(i, i) == char then
      return i
    end
  end
  return nil
end

-- Cut the cartridge out of the downloaded text without parsing it.
--
-- Measured in game: JSON.decode of a map costs 1.7 to 5.5 s in MoonSharp,
-- while the engine parses the very same JSON in 0.07 s inside
-- spawnObjectJSON. So the fastest decode is the one we never run - hand the
-- raw substring to the engine and let it do the single parse.
--
-- The shape a TTS save export produces is fixed, and it holds on all ten
-- featured maps: ObjectStates carries exactly one object, and the top-level
-- LuaScript / LuaScriptState / XmlUI / VersionNumber keys come after it.
-- The contained objects carry plain `"LuaScript"` keys of their own, but the
-- ObjectStates array closes before the top-level LuaScript key, so the last
-- occurrence in the file is always the top-level one - and the cartridge
-- ends at the last } before the ] just above it.
function extractCartridgeJson(text)
  local arrayKey = text:find('"ObjectStates"', 1, true)
  if not arrayKey then return nil end
  local objectStart = text:find("{", arrayKey, true)
  if not objectStart then return nil end

  local lastScript, pos = nil, arrayKey
  while true do
    local found = text:find('"LuaScript"', pos, true)
    if not found then break end
    lastScript, pos = found, found + 1
  end
  if not lastScript then return nil end

  local arrayEnd = lastCharBefore(text, "]", lastScript)
  if not arrayEnd then return nil end
  local objectEnd = lastCharBefore(text, "}", arrayEnd)
  if not objectEnd or objectEnd <= objectStart then return nil end

  return text:sub(objectStart, objectEnd)
end

-- Unpacking used to repair the links, decode 70-160 KB of JSON and encode the
-- cartridge back out, all in one frame - seconds of frozen table. The decode
-- and the encode are gone (see extractCartridgeJson); the link repair still
-- rebuilds the whole string, 0.07 to 0.41 s measured, so it waits a frame to
-- let the label paint first. Cutting the cartridge out costs 0.14 ms and
-- rides along in the same frame.
function unpackMap(text)
  printToScreen("UNPACKING MAP...", 80, 3)
  mapRuleSet(0)
  Wait.frames(function()
    text = repairDeadSteamHost(text)
    -- Every way out of here either loads the map or hands the menu back:
    -- the screen is showing UNPACKING MAP and nothing else would clear it.
    if not text:find('"ObjectStates"', 1, true) then
      printToAll("Could not download this map - the link may be broken or no longer hosts a valid map file.", {1, 0.5, 0.5})
      mapRuleHide()
      return mainMenu()
    end
    local json = extractCartridgeJson(text)
    if json == nil then
      -- Unexpected shape: pay for the full decode rather than fail.
      local map = safeJsonDecode(text)
      if not map or not map.ObjectStates or not map.ObjectStates[1] then
        printToAll("Could not download this map - the link may be broken or no longer hosts a valid map file.", {1, 0.5, 0.5})
        mapRuleHide()
        return mainMenu()
      end
      json = JSON.encode(map.ObjectStates[1])
    end
    -- Don't hold the whole file alive through the spawn cascade.
    text = nil
    local spawned = false
    spawnObjectJSON({
      json = json,
      position = dataDiskMount.getPosition(),
      callback_function = function(disk)
        spawned = true
        spawnMapFromCartridge(disk, function(abandoned)
          -- Restore the menu first: it is what lets the player act again,
          -- and the disk may already be gone by now.
          if not abandoned then mainMenu() end
          destroyIfAlive(disk)
        end)
      end
    })
    -- extractCartridgeJson trusts the shape of the file, and the featured
    -- list is fetched live, so one day a map may not match it. The engine
    -- rejects JSON it cannot read by never calling back at all - without
    -- this the screen would sit on UNPACKING MAP for ever, saying nothing.
    Wait.time(function()
      if not spawned then
        printToAll("Failed to unpack map.")
        mapRuleHide()
        mainMenu()
      end
    end, 10)
  end, 1)
end

function createMenu(optionTable, selectedIndex)
    clearAllButtons(backButton)

    if #optionTable > 5 then
        -- create prev and next buttons
        if selectedIndex-5 > 0 then
            _G["prevButtonFunction"] = function() createMenu(optionTable, selectedIndex-5) end
            changePrevButton("prevButtonFunction", "Previous Menu options")
        end
        if selectedIndex+4 < #optionTable then
            _G["nextButtonFunction"] = function() createMenu(optionTable,selectedIndex+5) end
            changeNextButton("nextButtonFunction", "More menu options")
        end
    end

    for oI=0,4,1 do
        if optionTable[selectedIndex+oI] ~= nil then
            local entry = optionTable[selectedIndex+oI]
            if entry.url ~= nil then
              optionUrls[selectedIndex+oI] = entry.url
              createOptionButton(oI+1, "downloadMap", entry.label,entry.tooltip, entry.buttonTint)
            else
              createOptionButton(oI+1, entry.functionName, entry.label,entry.tooltip, entry.buttonTint)
            end
        end
    end
end

function changeBattlefieldTint(tint)
    enterTintData(gameData, "battlefieldTint", tint)

    local allUnits = getAllObjects()
    for _,unit in pairs(allUnits) do
        if unit.getCustomObject().type == 1 then
            unit.setColorTint(tint)
            --unit.setTable("battlefieldTint", tint)
        end
    end
end

function onPlayerChangedColor(player_color)
    if player_color == "Red" or player_color == "Blue" then
        if Player[player_color].host == false and Player[player_color].promoted == false then
            Player[player_color].promote()
        end
    end
end

function enableExperimentalFeatures()
    ga_event("Global", "enableExperimentalFeatures")
    Global.UI.show("legionDisplay")
end

-- The masks and the POI guide are found by name rather than kept in
-- variables: a script reload (every save and load) resets the variables while
-- the projectors stay on the table, so toggling went wrong and left orphans.
function findObjectsByName(name)
    local matches = {}
    for _, obj in ipairs(getAllObjects()) do
        if obj.getName() == name then
            table.insert(matches, obj)
        end
    end
    return matches
end

function getExistingMaskLength()
    return #findObjectsByName("Masking Boundary")
end

function toggleMaskMid()   
    local length = getExistingMaskLength() 
    if length > 0 then
        clearMasks()
    else
        placeMask(35,9)
        placeMask(-19,9)
        placeMask(35,-9)
        placeMask(-19,-9)
    end
end

function toggleMaskRight()
    local length = getExistingMaskLength() 
    if length > 0 then
        clearMasks()
    else
        placeMask(35,9)
        placeMask(17,9)
        placeMask(35,-9)
        placeMask(17,-9)
    end
end

function toggleMaskLeft()
    local length = getExistingMaskLength() 
    if length > 0 then
        clearMasks()
    else
        placeMask(-1,9)
        placeMask(-19,9)
        placeMask(-1,-9)
        placeMask(-19,-9)
    end
end

function clearMasks()
    for _, obj in ipairs(findObjectsByName("Masking Boundary")) do
        destroyObject(obj)
    end
end

function placeMask(x, z)
    local projector = spawnObject({
        type        = "Custom_AssetBundle",
        position    = {
          x,
          75,
          z,
        },
        scale       = {0, 0, 0},
      })
      local asset = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/projector_masking_3x3_metal_v2.unity3d"
      projector.setName("Masking Boundary")
      projector.setLock(true)
      projector.setCustomObject({
        assetbundle = asset,
      })
end

function togglePoiGuide()
    local existing = findObjectsByName("Poi Guide")
    if #existing > 0 then
        for _, obj in ipairs(existing) do
            destroyObject(obj)
        end
    else
        local projector = spawnObject({
            type = "Custom_AssetBundle",
            position = { 8, 30, 0 },
            scale = {0,0,0}
        })
        local asset = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/poi_guide_isq_v3.unity3d"
        projector.setName("Poi Guide")
        projector.setLock(true)
        projector.setCustomObject({
            assetbundle = asset
        })
    end
end
-- MISSION (2024 rules)
--
-- Builds the mission from both players' battle decks on the TV, then places
-- the final cards on the setup mounts and runs their setup in rules order
-- (Objective, Secondary, then blue's and red's Advantage).
-- See includes/Mission.ttslua for the rules logic.

MISSION_SCENARIOS = {standard = true, skirmish = true}

MISSION_ACTION_LABELS = {
  replaceObjective       = "Replace Objective",
  replaceSecondary       = "Replace Secondary",
  replaceOwnAdvantage    = "Replace your Advantage",
  forceOpponentAdvantage = "Replace their Advantage",
  takeBlue               = "Become Blue Player",
  pass                   = "Pass",
}

MISSION_ACTION_TOOLTIPS = {
  replaceObjective       = "Replace the Objective with a random one from your deck",
  replaceSecondary       = "Replace the Secondary Objective with a random one from your deck",
  replaceOwnAdvantage    = "Replace your Advantage with a random one from your deck",
  forceOpponentAdvantage = "Make your opponent replace their Advantage with a random one from their deck",
  takeBlue               = "Become the blue player (blue chooses the table side)",
  pass                   = "Do nothing this turn",
}

missionCards = {}

-- Blank lines after the TV text push it up, clear of the card row.
MISSION_TEXT_PADDING = string.rep("\n", 19)

local function missionSeatName(seat)
  return seat .. " Player"
end

-- Returns the card names in the battle deck on a player's deck mount, or nil
-- and an error message.
local function readBattleDeck(seat)
  local zone = seat == "Red" and redDeckZone or blueDeckZone
  local names = {}
  for _, obj in ipairs(zone.getObjects()) do
    local type = obj.type or obj.tag
    if type == "Deck" then
      for _, entry in ipairs(obj.getObjects()) do
        local name = entry.nickname
        if name == nil or name == "" then
          name = entry.name
        end
        table.insert(names, name)
      end
    elseif type == "Card" then
      table.insert(names, obj.getName())
    end
  end
  if #names == 0 then
    return nil, missionSeatName(seat) .. ": no battle deck on your deck mount."
  end
  return names
end

local function readScenario(seat)
  local mount = seat == "Red" and redDeckMount or blueDeckMount
  local scenario = mount.call("getScenario")
  if scenario == "" then
    scenario = nil
  end
  -- Recon decks are keyed "skirmish" in the card data.
  return Deck:_scenarioKey(scenario)
end

-- Reads and checks both battle decks. Returns the decks and scenario, or nil
-- after telling the players what is wrong.
local function readMissionDecks()
  local decks = {}
  local scenario = nil
  local ok = true
  for _, seat in ipairs({"Blue", "Red"}) do
    local seatScenario = readScenario(seat)
    if not MISSION_SCENARIOS[seatScenario] then
      broadcastToAll(missionSeatName(seat) .. ": Build Mission supports Standard and Recon battle decks, not \"" .. seatScenario .. "\". Use the setup mounts to set up by hand.", {1, 0.4, 0.4})
      return nil
    end
    if scenario and scenario ~= seatScenario then
      broadcastToAll("Both battle decks must be the same type (Blue: " .. scenario .. ", Red: " .. seatScenario .. ").", {1, 0.4, 0.4})
      return nil
    end
    scenario = seatScenario

    local names, err = readBattleDeck(seat)
    if not names then
      broadcastToAll(err, {1, 0.4, 0.4})
      ok = false
    else
      local split, unknown = Deck:splitBattleDeck(names, scenario)
      if #unknown > 0 then
        broadcastToAll(missionSeatName(seat) .. ": ignoring cards that aren't " .. scenario .. " battle cards: " .. table.concat(unknown, ", "), {1, 0.8, 0.4})
      end
      for _, kind in ipairs(MISSION_KINDS) do
        local label = Deck.BATTLE_KINDS[kind].label
        local count = #split[kind]
        if count == 0 or (scenario == "standard" and count ~= 3) then
          broadcastToAll(missionSeatName(seat) .. ": your battle deck needs 3 " .. label .. " cards (found " .. count .. ").", {1, 0.4, 0.4})
          ok = false
        elseif count ~= 3 then
          broadcastToAll(missionSeatName(seat) .. ": battle decks normally have 3 " .. label .. " cards (found " .. count .. ").", {1, 0.8, 0.4})
        end
      end
      decks[seat] = split
    end
  end
  if not ok then
    return nil
  end
  return decks, scenario
end

function clearMissionCards()
  for _, card in pairs(missionCards) do
    if card ~= nil and not card.isDestroyed() then
      destroyObject(card)
    end
  end
  missionCards = {}
end

-- The mission's cards sit in one row along the bottom of the TV, left to
-- right: Objective, Secondary, blue's Advantage, red's Advantage. Offsets are
-- subtracted from the screen's position (as gameController.setUpCardsPos):
-- x and y place the row on the tilted screen, z spaces the cards.
MISSION_CARD_SCALE = 0.95
MISSION_CARD_ROW = {1.68, -1.21}
MISSION_CARD_COLUMNS = {-3.77, -1.17, 1.43, 4.03}

-- Shows a card on the TV in column 1..4.
local function showMissionCard(slotKey, column, kind, card)
  if missionCards[slotKey] and not missionCards[slotKey].isDestroyed() then
    destroyObject(missionCards[slotKey])
  end
  missionCards[slotKey] = nil
  if card == nil then
    return
  end
  local screenPos = screen.getPosition()
  local obj = Deck:spawnBattleCard(Deck.BATTLE_KINDS[kind].key, card.name, missionScenario)
  obj.setLock(true)
  obj.setScale({MISSION_CARD_SCALE, 1, MISSION_CARD_SCALE})
  obj.setRotation({55.91, 270.00, 0.00})
  obj.setPosition({
    screenPos.x - MISSION_CARD_ROW[1],
    screenPos.y - MISSION_CARD_ROW[2],
    screenPos.z - MISSION_CARD_COLUMNS[column],
  })
  obj.setDescription("From the " .. missionSeatName(card.owner) .. "'s battle deck")
  missionCards[slotKey] = obj
end

local function showMission()
  local blue = mission.blueSeat
  local red = Mission.otherSeat(blue)
  showMissionCard("objective", 1, "objective", mission.cards.objective)
  showMissionCard("secondary", 2, "secondary", mission.cards.secondary)
  showMissionCard("advantageBlue", 3, "advantage", mission.cards.advantage[blue])
  showMissionCard("advantageRed", 4, "advantage", mission.cards.advantage[red])
end

local function missionSummary()
  local blue = mission.blueSeat
  local red = Mission.otherSeat(blue)
  local function name(card)
    return card and card.name or "-"
  end
  return "Objective: " .. name(mission.cards.objective)
    .. "\nSecondary: " .. name(mission.cards.secondary)
    .. "\nBlue Advantage (" .. blue .. " seat): " .. name(mission.cards.advantage[blue])
    .. "\nRed Advantage (" .. red .. " seat): " .. name(mission.cards.advantage[red])
end

-- Step 1: read both decks.
function buildMissionMenu()
  ga_view("game_controller/build_mission")
  local decks, scenario = readMissionDecks()
  if not decks then
    return
  end
  clearMissionCards()
  setUpController.call("setAdvantageLabels", {})
  missionDecks = decks
  missionScenario = scenario
  mission = nil

  clearAllButtons()
  changeBackButton("reset", "Cancel and go back to Main Menu")
  createMenu({
    {functionName = "missionBlueIsBlue", label = "Blue Seat is Blue", tooltip = "The player at the blue seat is the blue player", buttonTint = {0, 0.4, 1}},
    {functionName = "missionRedIsBlue", label = "Red Seat is Blue", tooltip = "The player at the red seat is the blue player", buttonTint = {1, 0.2, 0.2}},
  }, 1)
  local modeName = scenario == "skirmish" and "RECON" or scenario:upper()
  printToScreen("BUILD MISSION (" .. modeName .. ")\n\nWho is the blue player?\n\nRoll off as the rules describe, then pick the winner below.", 70, 3)
end

local function startMission(blueSeat)
  mission = Mission:create({
    red      = missionDecks.Red,
    blue     = missionDecks.Blue,
    blueSeat = blueSeat,
  })
  clearAllButtons()
  changeBackButton("reset", "Cancel and go back to Main Menu")
  createMenu({
    {functionName = "missionRevealObjective", label = "Reveal Objective", tooltip = "Blue reveals an Objective; Red reveals a Secondary", buttonTint = {0, 0.913, 1}},
    {functionName = "missionRevealSecondary", label = "Reveal Secondary", tooltip = "Blue reveals a Secondary; Red reveals an Objective", buttonTint = {0, 0.913, 1}},
  }, 1)
  printToScreen("BUILD MISSION\n\n" .. missionSeatName(blueSeat) .. " (blue):\nreveal an Objective or a Secondary?\n\nThe red player reveals the other.\nBoth players reveal an Advantage.", 70, 3)
end

function missionBlueIsBlue()
  startMission("Blue")
end

function missionRedIsBlue()
  startMission("Red")
end

local function revealOpening(kind)
  mission:revealOpening(kind)
  showMission()
  missionTurnMenu()
end

function missionRevealObjective()
  revealOpening("objective")
end

function missionRevealSecondary()
  revealOpening("secondary")
end

-- Step 2: alternate modification turns.
function missionTurnMenu()
  if mission:isBuilt() then
    missionSideMenu()
    return
  end
  local seat = mission:currentSeat()
  local role = mission.blueSeat == seat and "blue" or "red"
  local turn = MISSION_TURNS - mission:turnsLeft() + 1
  local entries = {}
  for _, action in ipairs(mission:availableActions(seat)) do
    local functionName = "missionAction_" .. action
    _G[functionName] = function()
      local drawn = mission:modify(seat, action)
      local message = missionSeatName(seat) .. ": " .. MISSION_ACTION_LABELS[action]
      if drawn then
        message = message .. " -> " .. drawn.name
      end
      broadcastToAll(message, {0.8, 0.9, 1})
      showMission()
      missionTurnMenu()
    end
    table.insert(entries, {
      functionName = functionName,
      label        = MISSION_ACTION_LABELS[action],
      tooltip      = MISSION_ACTION_TOOLTIPS[action],
      buttonTint   = seat == "Red" and {1, 0.2, 0.2} or {0, 0.4, 1},
    })
  end
  clearAllButtons()
  changeBackButton("reset", "Cancel and go back to Main Menu")
  createMenu(entries, 1)
  printToScreen("MODIFY THE MISSION (turn " .. turn .. " of " .. MISSION_TURNS .. ")\n" .. missionSeatName(seat) .. " (" .. role .. ")\n\n" .. missionSummary() .. MISSION_TEXT_PADDING, 50, 2)
end

-- Step 3: blue picks a long edge. Players never change seats: picking the
-- far edge turns the battlefield around instead, so that edge's terrain ends
-- up in front of the blue player.
function missionSideMenu()
  clearAllButtons()
  changeBackButton("reset", "Cancel and go back to Main Menu")
  createMenu({
    {functionName = "missionEdgeNear", label = "Edge at My Seat", tooltip = "Keep the battlefield as it is: blue deploys on the edge in front of them", buttonTint = {0, 0.913, 1}},
    {functionName = "missionEdgeFar", label = "Far Edge (Flip Map)", tooltip = "Turn the battlefield around so the far edge's terrain is in front of the blue player", buttonTint = {0, 0.913, 1}},
  }, 1)
  printToScreen("MISSION BUILT\n" .. missionSeatName(mission.blueSeat) .. " (blue): choose your table edge.\nPlayers keep their seats: the far edge flips the map.\n" .. missionSummary() .. MISSION_TEXT_PADDING, 50, 2)
end

function missionEdgeNear()
  setUpMission(false)
end

function missionEdgeFar()
  setUpMission(true)
end

local function placeOnMount(mount, kind, name)
  local pos = mount.getPosition()
  local card = Deck:spawnBattleCard(Deck.BATTLE_KINDS[kind].key, name, missionScenario)
  card.setScale({0.83, 1, 0.83})
  card.setRotation(mount.getRotation())
  card.setPosition({pos.x, pos.y + 0.23, pos.z})
  return card
end

-- Step 4: put the final cards on the setup mounts and run their setup in
-- rules order: Objective, Secondary, blue's Advantage, red's Advantage.
-- flipBattlefield = true turns the battlefield around (blue picked the far
-- edge).
function setUpMission(flipBattlefield)
  ga_event("Game", "setUpMission")
  local result = mission:result()
  local red = Mission.otherSeat(result.blueSeat)
  clearMissionCards()
  setUpController.call("clearMountedCards")

  placeOnMount(setUpData.deploymentMount, "objective", result.objective)
  placeOnMount(setUpData.objectiveMount, "secondary", result.secondary)
  -- Each player's Advantage goes on the mount nearer their seat.
  local advantageMounts = {
    Blue = {mount = setUpData.advantageBlueSeatMount, check = "advantageBlueSeat"},
    Red  = {mount = setUpData.conditionsMount, check = "conditions"},
  }
  for _, seat in ipairs({"Blue", "Red"}) do
    local role = seat == result.blueSeat and "Blue" or "Red"
    local card = placeOnMount(advantageMounts[seat].mount, "advantage", result.advantage[seat])
    card.setDescription(role .. " player's Advantage (" .. seat .. " seat)")
  end
  setUpController.call("setAdvantageLabels", {blueSeat = result.blueSeat})

  -- Turn the terrain first, so the deployment zones drawn next stay put.
  if flipBattlefield then
    flipMap()
  end

  -- The blue player's zone is drawn on the blue player's side of the table.
  setUpController.call("changeScenario", {missionScenario})
  setUpController.call("setMirrorDeployment", {mirror = result.blueSeat == "Red"})

  -- Give the cards a moment to land in the mount zones before checking them.
  Wait.time(function()
    setUpController.call("checkCardCall", {"deployment"})
    setUpController.call("checkCardCall", {"objective"})
    -- The blue player's Advantage sets up before the red player's.
    setUpController.call("checkCardCall", {advantageMounts[result.blueSeat].check})
    setUpController.call("checkCardCall", {advantageMounts[red].check})
  end, 1)

  local summary = missionSummary():gsub("\n", ". ")
  broadcastToAll("Mission set up. " .. summary, {0.8, 0.9, 1})
  mission = nil
  mainMenu()
end
