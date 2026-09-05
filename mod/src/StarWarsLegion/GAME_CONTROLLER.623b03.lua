require('!/Analytics')
require('!/Deck')

existingMasks = {}
existingPoiGuide = nil

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
    objectiveCards = getObjectFromGUID(gameController.objectiveCardsGUID)
    deploymentCards = getObjectFromGUID(gameController.deploymentCardsGUID)
    conditionsCards = getObjectFromGUID(gameController.conditionsCardsGUID)
    setUpData = Global.getTable("setUpData")
    setUpData.deploymentMount = getObjectFromGUID(setUpData.deploymentMountGUID)
    setUpData.conditionsMount = getObjectFromGUID(setUpData.conditionsMountGUID)
    setUpData.objectiveMount = getObjectFromGUID(setUpData.objectiveMountGUID)
    commandTokenTrayData = Global.getTable("commandTokenTrayData")
    commandTokenData = Global.getTable("commandTokenData")
    zonesGUIDs = Global.getTable("zonesGUIDs")

    setUpController = getObjectFromGUID(Global.getVar("setUpControllerGUID"))
    battleDeckTypes = {"deployment", "objective", "conditions"}

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
    printToScreen("STAR WARS LEGION TTS MOD\n by SWL Dev Foundation\n\nThe home of BLITZ!\nSelect an option below to start", 80, 3)
end


-- MENU

function mainMenu()
    timerScreen = false

    printToScreen("STAR WARS LEGION TTS MOD\n by SWL Dev Foundation\n\nThe home of BLITZ!\nSelect an option below to start", 80, 3)

    clearAllButtons()
    local menuEntries = {}
    menuEntries[1] = {functionName = "mapMenu", label = "Maps", tooltip = "Map Menu", buttonTint = {0,0.913,1}}
    menuEntries[2] = {functionName = "gameOptionsMenu", label = "Set Up", tooltip = "Set Up options menu", buttonTint = {0,0.913,1}}

    createMenu(menuEntries, 1)

end

function defineBattlefieldMenuBlue()
    blueDeckMount.call("defineBattlefield")
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
    clearSetUpCards("all")
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

function defineBattlefieldMenu(params)
    local selectedDeck = params.deck
    local selectedScenario = params.scenario
    if #selectedDeck.getObjects() < 12 then
      broadcastToAll("At least 12 cards are required to use battlefield vetoes. Move your choices manually to the right places!")
      return
    end
    _G.selectedScenario = selectedScenario
    print(selectedScenario)
    ga_view("game_controller/define_battlefield")
    clearAllButtons()
    changeBackButton("reset", "Go back to Main Menu")
    local menuEntries = {}
    menuEntries[1] = {functionName = "finishDefineBattlefieldMenu", label = "NEXT", tooltip = "NEXT", buttonTint = {0,0.913,1}}
    createMenu(menuEntries, 1)
    revealBattleCards(selectedDeck, selectedScenario)
    printToScreen("DEFINE BATTLEFIELD\nStarting with Blue player, players eliminate left most card.\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", 60, 2)
end

function finishDefineBattlefieldMenu()
    defineBattlefield()
    spawnObjectiveConditionsDelay()
    mainMenu()
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
      functionName = "defineBattlefieldMenuBlue",
      label = "Blue Player: Define Battlefield",
      tooltip = "Spawn Battlefield Objective, Deployment and Condition cards from Blue Deck",
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
    createMenu(menuEntries, 1)
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

function featuredCompetitiveMenu()
  ga_view("game_controller/featured_maps/competitive")
  printToScreen("FEATURED MAPS\n\nThese are maps featured by the community.\n\nSee https://go.swlegion.dev/maps for details.", 80, 3)
  changeBackButton("featuredMapsMenu", "Go back to featured maps")
  local url = "https://raw.githubusercontent.com/swlegion/tts/master/contrib/maps/competitive.json"
  WebRequest.get(url, function(data)
    -- GitHub answers an outage or a hiccup with an HTML page, and decoding
    -- that raises inside the download handler where nothing catches it.
    local ok, items = pcall(function() return JSON.decode(data.text) end)
    if not ok or type(items) ~= "table" then
      printToAll("Could not read the featured map list. Check your connection.")
      return mainMenu()
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
    -- GitHub answers an outage or a hiccup with an HTML page, and decoding
    -- that raises inside the download handler where nothing catches it.
    local ok, items = pcall(function() return JSON.decode(data.text) end)
    if not ok or type(items) ~= "table" then
      printToAll("Could not read the featured map list. Check your connection.")
      return mainMenu()
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

function setBattleCardPos()
    for i, battleDeckType in pairs(battleDeckTypes) do
        for n=1, 4, 1 do
            local setUpCardPos = gameController.setUpCardsPos[battleDeckType][n]
            local spawnPos = {}
            
            spawnPos.x = screen.getPosition().x - setUpCardPos[1]
            spawnPos.y = screen.getPosition().y - setUpCardPos[2]
            spawnPos.z = screen.getPosition().z - setUpCardPos[3]

            local spawnRot = {55.91, 270.00, 0.00}
            local spawnedCardObj = setUp5Data.spawnedCards[battleDeckType][n]

            spawnedCardObj.setLock(true)
            spawnedCardObj.setScale({0.5,1,0.5})
            spawnedCardObj.setRotation(spawnRot)
            spawnedCardObj.setPosition(spawnPos)

            Wait.frames(function()
              debugSpawnSetupCard(spawnedCardObj)
            end)
        end
    end
end

function createMatrixFromDeck(battleDeckInserted, battleDeckScenario)
  -- CLONE DECK
  local battleDeckClone = battleDeckInserted.clone({
      position     = {0,-10,0},
      rotation     = {55.91, 270.00, 0.00},
      scale        = {0.5, 1, 0.5},
  })
  battleDeckClone.shuffle()
  local battleDeckTable = battleDeckClone.getObjects()

  -- for each card
  
  local cardMatrixSelected = {
    deployment = {},
    objective  = {},
    conditions = {},
  }

  for i, card in ipairs(battleDeckClone.getObjects()) do
    local object = battleDeckClone.takeObject({
      position     = {i*1, -10, 0},
    })
    local name = object.getName()
    local type = Deck:getBattleCardType(name, battleDeckScenario)
    -- TODO: Rename conditions -> condition
    if type == "condition" then
      type = "conditions"
    end
    table.insert(cardMatrixSelected[type], object)
  end

  if battleDeckClone then
    destroyObject(battleDeckClone)
  end

  return cardMatrixSelected.objective, 
         cardMatrixSelected.deployment,
         cardMatrixSelected.conditions
end

function revealBattleCards(insertedDeck, battleDeckScenario)
    clearSetUpCards("all")
    setUp5Data = {
      objectiveCards  = objectiveCards,
      deploymentCards = deploymentCards,
      conditionsCards = conditionsCards,
      spawnedCards    = {},
    }
    if insertedDeck == nil then
        setUp5Data.spawnedCards.objective = spawnSetupCards("objective")
        setUp5Data.spawnedCards.deployment = spawnSetupCards("deployment")
        setUp5Data.spawnedCards.conditions = spawnSetupCards("conditions")
    else
        objectiveCardMatrix, deploymentCardMatrix, conditionsCardMatrix = createMatrixFromDeck(insertedDeck, battleDeckScenario)
        setUp5Data.spawnedCards.objective = objectiveCardMatrix
        setUp5Data.spawnedCards.deployment = deploymentCardMatrix
        setUp5Data.spawnedCards.conditions = conditionsCardMatrix
        setBattleCardPos()
    end
    setUp5Data.cardSelection = {objective = 1, deployment = 1, conditions = 1}

    createButtonSetUpCard("objective", 1)
    createButtonSetUpCard("deployment", 1)
    createButtonSetUpCard("conditions", 1)
    Wait.frames(debugSetupCards)
end

function debugSetupCards()
    for i = 1, 4, 1 do
        if setUp5Data.spawnedCards.objective[i] then
            setUp5Data.spawnedCards.objective[i].setRotation({55.91, 270.00, 0.00})
        end

        if setUp5Data.spawnedCards.deployment[i] then
            setUp5Data.spawnedCards.deployment[i].setRotation({55.91, 270.00, 0.00})
        end
        if setUp5Data.spawnedCards.conditions[i] then
            setUp5Data.spawnedCards.conditions[i].setRotation({55.91, 270.00, 0.00})
        end
    end
end

function clearSetUpCards(clearedCards)
    if setUp5Data then
        for i = 1, 4, 1 do
            if setUp5Data.cardSelection.objective == i and clearedCards == "eliminate" then
            else
                if setUp5Data.spawnedCards.objective[i] then
                    destroyObject(setUp5Data.spawnedCards.objective[i])
                end
            end

            if setUp5Data.cardSelection.deployment == i and clearedCards == "eliminate" then
            else
                if setUp5Data.spawnedCards.deployment[i] then
                    destroyObject(setUp5Data.spawnedCards.deployment[i])
                end
            end

            if setUp5Data.cardSelection.conditions == i and clearedCards == "eliminate" then
            else
                if setUp5Data.spawnedCards.conditions[i] then
                    destroyObject(setUp5Data.spawnedCards.conditions[i])
                end
            end
        end
    end

    if clearedCards == "all" then
        setUp5Data = nil
    end

end

function defineBattlefield()
    clearSetUpCards("eliminate")
    insertSetUpCard("objective")
    insertSetUpCard("deployment")
    insertSetUpCard("conditions")
end

function insertSetUpCard(cardType)
    local mount = setUpData[cardType.."Mount"]
    local finalPos = {mount.getPosition().x, mount.getPosition().y+0.23, mount.getPosition().z}
    local finalCard = setUp5Data.spawnedCards[cardType][setUp5Data.cardSelection[cardType]]
    finalCard.setScale({0.83,1,0.83})
    finalCard.setLock(false)
    finalCard.setPosition(finalPos)
    finalCard.setRotation(mount.getRotation())
    finalCard.clearButtons()
end

function spawnObjectiveConditionsDelay()
    Wait.frames(spawnObjectiveConditions)
end

function spawnObjectiveConditions()
    local scenario = _G.selectedScenario
    setUpController.call("changeScenario", {scenario})
    setUpController.call("checkCardCall", {"deployment"})
    setUpController.call("checkCardCall", {"objective"})
    setUpController.call("checkCardCall", {"conditions"})
end


function eliminateCard(eliminatedCategory, eliminateNumber)
    local eliminiatedCard = setUp5Data.spawnedCards[eliminatedCategory][eliminateNumber]
    local cardRot = eliminiatedCard.getRotation()
    cardRot.x = cardRot.x + 180
    eliminiatedCard.setRotation(cardRot)
    eliminiatedCard.clearButtons()

    if eliminateNumber ~= 3 then
        createButtonSetUpCard(eliminatedCategory, eliminateNumber+1)
    end

    setUp5Data.cardSelection[eliminatedCategory] = eliminateNumber+1
end

function createButtonSetUpCard(cardType, selectedNumber)
    _G["eliminate"..cardType..selectedNumber] = function() eliminateCard(cardType, selectedNumber) end

    local data = {click_function = "eliminate"..cardType..selectedNumber, function_owner = self, label = "ELIMINATE", position = {-1, 1, 0}, rotation = {0, -90, 0}, scale = {0.7, 0.5, 0.5}, width = 2000, height = 400, font_size = 300, color = {1, 0, 0, 0.8}, font_color = {0,0,0, 1.25}}

    setUp5Data.spawnedCards[cardType][selectedNumber].createButton(data)
end

function spawnSetupCards(selection)
        setUp5Data[selection.."CardsClone"] = setUp5Data[selection .."Cards"].clone({
            position     = {0,-10,0}
        })

        setUp5Data[selection.."CardsClone"].shuffle()

        local spawnedCardTable = {}

        for n=1, #gameController.setUpCardsPos[selection], 1 do
            local setUpCardPos = gameController.setUpCardsPos[selection][n]

            local spawnPos = {}
            spawnPos.x = screen.getPosition().x - setUpCardPos[1]
            spawnPos.y = screen.getPosition().y - setUpCardPos[2]
            spawnPos.z = screen.getPosition().z - setUpCardPos[3]

            local spawnRot = {55.91, 270.00, 0.00}

            spawnedCard = setUp5Data[selection.."CardsClone"].takeObject({
                position       = spawnPos,
                rotation       = spawnRot,
                smooth         = false,
                top            = true
            })

            spawnedCard.setLock(true)
            spawnedCard.setRotation(spawnRot)

            spawnedCardTable[n] = spawnedCard

            Wait.frames(function()
              debugSpawnSetupCard(spawnedCard)
            end)
        end

        destroyObject(setUp5Data[selection.."CardsClone"])

        return spawnedCardTable
end

function debugSpawnSetupCard(spawnedSetupCard)
    spawnedSetupCard.setRotation({55.91, 270.00, 0.00})
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

-- The progress rule along the top of the screen (isqProgressRule in the
-- Global XML, the band every loading indicator of the mod shares). pcall:
-- a save whose XML predates the element must not break a map load.
function mapRuleSet(pct)
  pcall(function()
    UI.setAttribute("isqProgressRuleFill", "width", math.floor(pct) .. "%")
    UI.setAttribute("isqProgressRule", "active", "true")
  end)
end

function mapRuleHide()
  pcall(function() UI.setAttribute("isqProgressRule", "active", "false") end)
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
  -- Geonosis, "Destroyed Advanced Dwarf Spider Droid": NOT substituted, on
  -- purpose. The only other copy in circulation is a different sculpt whose
  -- texture does not match, and swapping to it is worse than leaving the
  -- dead link: a player who owns the real one has it in their TTS cache, and
  -- pointing somewhere else is exactly what stops them seeing it. The two
  -- original files survive in a cache and are waiting to be rehosted; until
  -- then the piece is missing for a fresh install and correct for everyone
  -- who played this map before it died.
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
  -- any cache or archive. Nothing can bring this decorative dust effect
  -- back, so drop it rather than keep pointing at a host that will never
  -- answer again.
  ["http://infinitebucket.com/tts/scenesystem/dust.unity3d"] = "",
}

-- Featured Map assets whose hosts nobody controls any more: personal imgur
-- accounts, one map author's Dropbox, anonymous gists, a pastebin, a texture
-- site. Every one of them still answered when the mirror was taken, which is
-- exactly the moment to copy a file rather than the moment after. Keyed by
-- the URL the map data carries, verbatim; the value is the file name in our
-- store. The 196 assets these same maps pull from Steam's CDN are left
-- alone: that is the host the whole mod already rests on, so mirroring them
-- would buy no safety and cost 58 MB.
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
  ["https://gist.githubusercontent.com/nashjaee/3375e9ebe255d751196483c59c545591/raw/fe2fa562af6874076a3dc4e0f74dc7c68eeafa63/rock_formation_collider.txt"] =
    "268c4fa83f51fd727b8f.obj",
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
  ["https://gist.githubusercontent.com/nashjaee/b9048effba06e7d8baaaacb0594c885b/raw/b71c618b6498c858ae3c55da102c1eaee6c3709e/rock_formation_2_collider.txt"] =
    "b028d3e6aa20b1507ab5.obj",
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
ISQ_STORE = "https://raw.githubusercontent.com/ironsquadronfr-hub/swl-assets/main/assets/"

local function applySwaps(text, swaps, prefix)
  for from, to in pairs(swaps) do
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

function repairDeadSteamHost(text)
  local repaired = text:gsub("https?://cloud%-3%.steamusercontent%.com/", "https://steamusercontent-a.akamaihd.net/")
  repaired = applySwaps(repaired, DEAD_UGC_SWAPS)
  repaired = applySwaps(repaired, MIRRORED_ASSETS, ISQ_STORE)
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
      printToAll("Failed to download map.")
      mapRuleHide()
      return mainMenu()
    end
    local json = extractCartridgeJson(text)
    if json == nil then
      -- Unexpected shape: pay for the full decode rather than fail.
      local map = JSON.decode(text)
      if not map or not map.ObjectStates or not map.ObjectStates[1] then
        printToAll("Failed to decode map.")
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

function getExistingMaskLength()
    local length = 0
    if existingMasks != nil then
        for i, obj in pairs(existingMasks) do
            length = length + 1
        end
    end
    return length
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
    if existingMasks != nil then
        for i, obj in pairs(existingMasks) do
            if obj != nil then
                destroyObject(obj)
            end
        end
        existingMasks = {}
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
      local asset = "https://steamusercontent-a.akamaihd.net/ugc/2264809616949875099/DB2BBB502F11E04185A603B8A4FD0F2391B905C6/"
      projector.setName("Masking Boundary")
      projector.setLock(true)
      projector.setCustomObject({
        assetbundle = asset,
      })  
    table.insert(existingMasks, projector)
end

function togglePoiGuide()   
    local length = getExistingMaskLength() 
    if existingPoiGuide ~= nil then
        destroyObject(existingPoiGuide)
        existingPoiGuide = nil
    else
        local projector = spawnObject({
            type = "Custom_AssetBundle",
            position = { 8, 30, 0 },
            scale = {0,0,0}
        })
        local asset = "https://steamusercontent-a.akamaihd.net/ugc/2491137781649901469/35992792768FE398E61633C99C02D069A54F65B1/"
        projector.setName("Poi Guide")
        projector.setLock(true)
        projector.setCustomObject({
            assetbundle = asset
        })
        existingPoiGuide = projector
    end
end