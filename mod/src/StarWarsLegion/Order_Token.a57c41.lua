require('!/common/Math')
require('!/RangeRulers')
require('!/data/MovementLinks')
require('!/Cohesion')


-- Model Token

function onload()
  -- LOAD VALUES
  _G.battlefieldZone = getObjectFromGUID(Global.getVar("battlefieldZoneGUID"))
  _G.templateInfo = Global.getTable("templateInfo")
  _G.highlightTints = Global.getTable("highlightTints")

  -- set info
  _G.selectedUnit = nil
  _G.activated = false

  -- setUp
  if _G.unitData ~= nil then
    local dieRollerInfo = Global.getTable("dieRollerInfo")
    _G.isAToken = true
    _G.dieRoller = getObjectFromGUID(dieRollerInfo[_G.unitData.colorSide.."DieRollerGUID"])
    setTemplateVariables()
    initialize()
  end
end

--
function setTemplateVariables()
    unitData.aStart = templateInfo.aStart[unitData.baseSize][unitData.selectedSpeed]
    unitData.templateMesh = templateInfo.templateMesh[unitData.selectedSpeed]
    unitData.templateBallCollider = templateInfo.templateBallCollider
    unitData.tint = templateInfo.tint[unitData.selectedSpeed]
    unitData.buttonPosition = templateInfo.buttonPosition[unitData.selectedSpeed]
    unitData.buttonColor = templateInfo.buttonColor[unitData.selectedSpeed]
    unitData.fontColor = templateInfo.fontColor[unitData.selectedSpeed]
end
------------------------------------------------- MATH FIND PROXIMITY------------------------------------------------------------
function findProximity(targetObj, object)
    local objectPos = object.getPosition()
    local targetPos = targetObj.getPosition()

    local xDistance = math.abs(targetPos.x - objectPos.x)
    local zDistance = math.abs(targetPos.z - objectPos.z)
    local distance = xDistance^2 + zDistance^2
    return math.sqrt(distance)
end




------------------------------------------------- getSelectedUnit() ------------------------------------------------------------
function getEligibleUnit()
    eligibleUnits = nil
    eligibleUnits = {}
    eligibleUnitsNumber = 0
    selectedUnitObj = nil

    local allUnits = nil
    local allUnits = battlefieldZone.getObjects()

    if allUnits ~= nil then
        local closestDistance = 9999999999999

        -- check all units
        for i, unit in pairs(allUnits) do
            -- check eligibility

            local miniData = unit.getTable("unitData")
            local isAMini = unit.getVar("isAMini")
            if miniData and miniData.commandType then
                if isAMini == true and unitData.commandType == miniData.commandType and unit.getVar("colorSide") == unitData.colorSide then
                    -- add to eligible units
                    eligibleUnitsNumber = eligibleUnitsNumber + 1
                    eligibleUnits[eligibleUnitsNumber] = unit

                    -- find distance
                    local distance = findProximity(self, unit)


                    if distance < closestDistance then
                        selectedUnitObj = unit
                        selectedUnitNumber = eligibleUnitsNumber
                        closestDistance = distance
                    end
                end
            end

        end
        -- if success
        if selectedUnitObj then
            getSelectedUnitObjVariables()
            setTemplateVariables()
        end
    end
end

function highlightUnit(selectedMiniGUIDs, highlightColor)
  for _, guidEntry in ipairs(selectedMiniGUIDs) do
    obj = getObjectFromGUID(guidEntry)
    if obj then
      obj.highlightOn(highlightColor)
    end
  end
end

function unhighlightUnit(selectedMiniGUIDs)
    if selectedMiniGUIDs then
        for k, guidEntry in pairs(selectedMiniGUIDs) do
            obj = getObjectFromGUID(guidEntry)
            if obj then
                obj.highlightOff()
            end
        end
    end
end

function highlightCard(selectedUnitCard)
    if selectedUnitCard then
        selectedUnitCard.highlightOn({0,1,0})
    end
end

function forceUnhighlight()
    local allObjs = getAllObjects()
    for _, obj in pairs(allObjs) do
        obj.highlightOff()
    end
end


function unHighlightCard(selectedUnitCard)
    if selectedUnitCard then
        selectedUnitCard.highlightOff()
    end
end

function getSelectedUnitObjVariables()
    if selectedUnitObj then
        newUnitData = selectedUnitObj.getTable("unitData")
        unitData.baseSize = newUnitData.baseSize
        unitData.selectedSpeed = newUnitData.selectedSpeed
    end
end

------------------------------------------------- STANDBY ------------------------------------------------------------
function initialize()

    activated = false
    --getEligibleUnit()

    createStandbyButtons()

end

function createStandbyButtons()
    if selectedUnitObj then
        self.createButton({
            click_function = "activate",
            function_owner = self,
            label = "ACT", position = {0, 0.05, 0.4}, width = 350, height = 250, font_size = 120, color = {0.03, 0.6, 0.03, 1}, font_color = {1, 1, 1, 1},
            tooltip = "Activate nearest " .. unitData.commandType .. " unit",
            color = {0.03, 0.6, 0.03}
        })
    else

        self.createButton({
            click_function = "standby",
            function_owner = self,
            label = "",
            position = {0, 0.05, 0.4}, width = 350, height = 250,
            font_size = 150,
            tooltip = "No unit of this type left on board",
            color = {0.6, 0.03, 0.03},
            font_color = {1, 1, 1}
        })
    end
end

function standby()
    activated = false
    self.clearButtons()
    clearTemplates()
    forceUnhighlight()

    getEligibleUnit()

    createStandbyButtons()
end
------------------------------------------------- ACTIVATE ------------------------------------------------------------
function activate()
  getEligibleUnit()
  if selectedUnitObj then
    moveDirection = "forward"
    activated = true
    self.clearButtons()
    getSelectedUnitObjVariables()
    setTemplateVariables()

    selectedUnitObj.call("setStartPos")

    highlightUnit(selectedUnitObj.getTable("miniGUIDs"),{0,1,0})
    highlightCard(getObjectFromGUID(selectedUnitObj.getVar("cardGUID")))

    resetButtons()
  else
    standby()
  end
end
------------------------------------------------- ResetButtons------------------------------------------------------------
function resetButtons()
    self.clearButtons()
    if selectedUnitObj then

        self.createButton({
            click_function = "nextUnit",
            function_owner = self,
            label = "NEXT",
            position = {0, 0.2, -1.2},
            width = 550,
            height = 350,
            font_size = 150,
            tooltip = "Toggle between " .. selectedUnitObj.getName() .. " Units",
            font_color = {0,0,0},
            color = {1, 0.9946, 0, 1}
        })

        self.createButton({
            click_function = "initMove",
            function_owner = self,
            label = "  MOVE",
            position = {1.7, 0.2, 0.4},
            width = 750,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0.9167, 0.9167, 0.9167, 1},
            tooltip = "Spawn movement templates. Unit leader spawns cohesion rulers when moved"
        })

        self.createButton({
            click_function = "aim",
            function_owner = self,
            label = "A",
            position = {-2, 0.2, -0.4},
            width = 370,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0, 0.8705, 0.0941, 1},
            tooltip = "Take an Aim token",
            alignment = 2
        })

        self.createButton({
            click_function = "attack",
            function_owner = self,
            label = "  ATTACK",
            position = {1.6, 0.2, 1.2},
            width = 850,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {1, 0, 0, 1},
            tooltip = "Draw Attack Die or Spawn Range Rulers"
        })

        self.createButton({
            click_function = "dodge",
            function_owner = self,
            label = "D",
            position = {-1.1, 0.2, -0.4},
            width = 370,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0, 0.8705, 0.0941, 1},
            tooltip = "Take a Dodge token"
        })

        self.createButton({
            click_function = "overwatch",
            function_owner = self,
            label = "ST",
            position = {-2, 0.2, 0.4},
            width = 370,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0.65, 0.65, 0.65, 1},
            tooltip = "Take a Standby token"
        })

        self.createButton({
            click_function = "surge",
            function_owner = self,
            label = "SU",
            position = {-1.1, 0.2, 0.4},
            width = 370,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0, 0.8705, 0.0941, 1},
            tooltip = "Take a Surge token"
        })

        self.createButton({
            click_function = "initDeploy",
            function_owner = self,
            label = "DEPLOY",
            position = {-1.6, 0.2, 1.2},
            width = 850,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0, 0.8705, 0.0941, 1},
            tooltip = "Start a Deploy Move"
        })

        self.createButton({
            click_function = "resetActivation",
            function_owner = self,
            label = "X            ",
            position = {-1.6, 0.2, -1.2},
            width = 850,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {1, 0.9135, 0, 1},
            tooltip = "Cancel",
        })

        self.createButton({
            click_function = "endActivation",
            function_owner = self,
            label = "END",
            position = {0, 0.2, 1.2},
            width = 550,
            height = 350,
            font_size = 150,
            color = {0.7, 0.03, 0.03, 1},
            font_color = {1, 1, 1, 1},
            tooltip = "End your Activation",
        })

        self.createButton({
            click_function = "toggleCohesionRuler",
            function_owner = self,
            label = "COHESION", position = {1.6, 0.2, -1.2}, width = 850, height = 350, font_size = 150, color = {0, 0, 0, 1}, font_color = {0.4709, 0.9759, 0.9162, 1},
            tooltip = "Spawn Cohesion Rulers"
        })

        self.createButton({
            click_function = "targetingMode",
            function_owner = self,
            label = "  RANGE",
            position = {1.7, 0.2, -0.4},
            width = 750,
            height = 350,
            font_size = 150,
            color = {0, 0, 0, 1},
            font_color = {0.4709, 0.9759, 0.9162, 1},
            tooltip = "Spawn Range Rulers"
        })
    end
end

function toggleCohesionRuler()
    -- Iron Squadron overlays (see !/IsqOverlays): route this button to the
    -- Projector renderer when they are on. Off by default, in which case
    -- everything below runs unchanged.
    if isqOverlaysOn() then
        if not selectedUnitObj then return end
        -- Clear before toggling on: the hover hotkey writes to the same key as
        -- this unit, so without the clear the first click here would turn that
        -- overlay off while we set rulerOn = true, leaving the button inverted
        -- from then on.
        isqClearCohesion({figGUID = selectedUnitObj.getGUID()})
        if rulerOn then
            rulerOn = false
        else
            isqToggleCohesion({figGUID = selectedUnitObj.getGUID()})
            rulerOn = true
        end
        return
    end
    if not rulerOn then
        selectedUnitObj.call("spawnCohesionRuler", selectedUnitObj)
        rulerOn = true
    else
        selectedUnitObj.call("clearCohesionRuler")
        rulerOn = false
    end

end

------------------------------------------------- NEXTUNIT ------------------------------------------------------------
function nextUnit()
    local out = false
    local originalUnitNumber = selectedUnitNumber
    while out == false do
        -- ++ selection
        selectedUnitNumber = selectedUnitNumber + 1
        -- loop selection
        if selectedUnitNumber > eligibleUnitsNumber then
            selectedUnitNumber = 1
        end
        -- check if back to originalUnitNumber
        if selectedUnitNumber == originalUnitNumber then
            out = true
            if selectedUnitObj == nil then
                standby()
            end
        else
            -- examine nil status
            if eligibleUnits[selectedUnitNumber] then
                clearTint()
                stopUnit()
                stopAttack()
                selectedUnitObj = eligibleUnits[selectedUnitNumber]

                selectedUnitObj.call("setStartPos")
                highlightUnit(selectedUnitObj.getTable("miniGUIDs"),{0,1,0})
                highlightCard(getObjectFromGUID(selectedUnitObj.getVar("cardGUID")))
                getSelectedUnitObjVariables()
                setTemplateVariables()
                out = true
            end
        end


    end

end

function clearTint()
    unhighlightEnemies()

    if selectedUnitObj then
        unhighlightUnit(selectedUnitObj.getTable("miniGUIDs"))
        unHighlightCard(getObjectFromGUID(selectedUnitObj.getVar("cardGUID")))
    end
end
------------------------------------------------- MOVE UNIT ------------------------------------------------------------
function initMove()
    initPos = selectedUnitObj.getPosition()
    initRot = selectedUnitObj.getRotation()
    selectedUnitObj.call("setStartPos")
    moveUnit(false)
end

function initDeploy()
    initPos = selectedUnitObj.getPosition()
    initRot = selectedUnitObj.getRotation()
    selectedUnitObj.call("setStartPos")   
    moveUnit(true)
end


function moveUnit(isDeploy)
    local startOffset = 0.0
    if isDeploy and isDeploy == true then
        local baseSize = unitData.baseSize
        startOffset = templateInfo.deployMod[baseSize]
    end
    stopAttack()
    resetButtons()
    clearTemplates()
    selectedUnitObj.setVar("moveState", true)
    self.editButton({
        index = 1,
        click_function = "stopUnit",
        label = "  DONE",
        color = {0.7, 0.03, 0.03},
        font_color = {1, 1, 1}
    })
    lockUnitsExcept(selectedUnitObj, "MoveInProgress")

    ------------------------------------------- PLACEMENT MATH -------------------------------------------
    basePos = selectedUnitObj.getPosition()
    basePos.y = basePos.y + 0.05
    baseRot = selectedUnitObj.getRotation()

    if moveDirection == "backward" then
        baseRot.y = baseRot.y + 180

    elseif moveDirection == "left" then
        baseRot.y = baseRot.y - 90
    elseif moveDirection == "right" then
        baseRot.y = baseRot.y + 90
    end

    local q = math.rad(baseRot.y)
    local a = (unitData.aStart + startOffset) * math.cos(q)
    local b = (unitData.aStart + startOffset) * math.sin(q)

    ------------------------------------------- SPAWN TEMPLATES -------------------------------------------

    local modelTemplateA = getObjectFromGUID(templateInfo.modelTemplateAGUID)

    templateA = spawnObject({
        type = "Custom_AssetBundle",
        position = {basePos.x - b, basePos.y, basePos.z - a},
        rotation = {0, baseRot.y + 180, 0},        
        scale = {1,1,1}
    })
    templateA.setCustomObject({
        type = 0,
        assetbundle = templateInfo.moveTemplate[unitData.selectedSpeed].longBundle,
        assetbundle_secondary = templateInfo.moveTemplate[unitData.selectedSpeed].sharedBundle,
        material = 1,
    })

    templateA.mass = 0.0

    local templateLuaScriptA = "unitInfo = {}\nunitInfo.baseSize = '"..unitData.baseSize.."'\nunitInfo.selectedSpeed = "..unitData.selectedSpeed.."\n"..modelTemplateA.getLuaScript()

    templateA.setLuaScript(templateLuaScriptA)
    templateA.sticky = false
    templateA.setName("Movement Template (A)")
    templateA.setColorTint(templateInfo.moveTemplate[unitData.selectedSpeed].colorTint)

    local modelTemplateB = getObjectFromGUID(templateInfo.modelTemplateBGUID)

    templateB = spawnObject({
        type = "Custom_AssetBundle",
        position = {basePos.x - b, basePos.y, basePos.z - a},
        rotation = {0, baseRot.y, 0},
        --make the second bit a tiny bit taller to stop zfighting at the joint
        scale = {1,1.1,1}
    })
    templateB.setCustomObject({
        type = 0,
        assetbundle = templateInfo.moveTemplate[unitData.selectedSpeed].shortBundle,
        assetbundle_secondary = templateInfo.moveTemplate[unitData.selectedSpeed].sharedBundle,
        material = 1
    })

    templateB.mass = 0.0

    local templateLuaScriptB = "unitInfo = {}\nunitInfo.baseSize = '"..unitData.baseSize.."'\nunitInfo.selectedSpeed = "..unitData.selectedSpeed.."\n"..modelTemplateB.getLuaScript()

    templateB.setLuaScript(templateLuaScriptB)
    templateB.sticky = false
    templateB.setName("Movement Template (B)")
    templateB.setColorTint(templateInfo.moveTemplate[unitData.selectedSpeed].colorTint)

    -- SET VALUES

    templateA.setTable("basePos", basePos)
    templateA.setTable("baseRot", baseRot)
    templateA.setVar("templateB", templateB)

    local fixedMove = false
    if isDeploy then
        fixedMove = true
    else
        fixedMove = unitData.baseSize ~= "small"
    end
    templateA.setLock(fixedMove)

    templateB.setTable("basePos", basePos)
    templateB.setTable("baseRot", baseRot)
    templateB.setVar("templateA", templateA)
    templateB.setLock(false)

    templateA.setVar("isDeploy", isDeploy)

    local maxMoveBundles = getMovementLinks()
    local baseSizeMoveBundles = maxMoveBundles[unitData.baseSize]
    local maxMoveTemplateBundleToSpawn = baseSizeMoveBundles[unitData.selectedSpeed]

    -- changeSpeed1/2/3 rappellent moveUnit() sans argument apres avoir detruit
    -- les gabarits, donc isDeploy vaut nil et non false. Avec une egalite
    -- stricte, le cercle de mouvement disparaissait des qu'on changeait de
    -- vitesse et ne revenait jamais.
    if isDeploy ~= true then
        --max movement ring projector
        if maxMoveTemplateBundleToSpawn ~= nil then
            maxMoveTemplate = spawnObject({
                type = "Custom_AssetBundle",
                position = {basePos.x, basePos.y + 20, basePos.z},
                -- Le lacet se prend sur baseRot.y, l'orientation de l'unite.
                -- Il valait basePos.y, c'est-a-dire sa HAUTEUR au-dessus de la
                -- table : le projecteur etait donc toujours pose a ~1 degre dans
                -- le repere du monde, sans jamais suivre le vehicule. Invisible
                -- tant que l'empreinte est un disque, faux des qu'elle ne l'est
                -- plus.
                rotation = {0, baseRot.y, 0},
                scale = {0,0,0} -- 0 scale will hide TTS default box and won't impact projector
            })

            maxMoveTemplate.setCustomObject({
                type = 0,
                assetbundle = maxMoveTemplateBundleToSpawn
            })

            maxMoveTemplate.setLock(true)
            maxMoveTemplate.use_gravity = false
            maxMoveTemplate.setName("Maximum Move")
        end
    end
    ------------------------------------------- SPAWN BUTTON -------------------------------------------


    local data = {click_function = "INSERT_FUNCTION", function_owner = self, label = "1", position = {3, 0.2, -0.4}, width = 300, height = 350, font_size = 200, tooltip = "1"}

    self.createButton({
        click_function = "changeSpeed1",
        function_owner = self,
        label = "1", position = {3, 0.2, -0.4}, width = 300, height = 350, font_size = 200,
        tooltip = "Move Speed 1",
        color = {1, 1, 1},
        font_color = {0, 0, 0}
    })

    self.createButton({
        click_function = "changeSpeed2",
        function_owner = self,
        label = "2", position = {3, 0.2, 0.4}, width = 300, height = 350, font_size = 200, color = {0, 0, 0, 1}, font_color = {1, 1, 1, 1},
        tooltip = "Move Speed 2"
    })
    self.createButton({
        click_function = "changeSpeed3",
        function_owner = self,
        label = "3",
        position = {3, 0.2, 1.2}, width = 300, height = 350, font_size = 200, color = {0.8103, 0.0857, 0.0857, 1}, font_color = {1, 1, 1, 1},
        tooltip = "Move Speed 3"
    })
    if fixedMove then

        if true then -- TODO: Is it worth enforcing this? "unitData.strafeMove" 

              self.createButton({
                  click_function = "moveForward",
                  function_owner = self,
                  label = "F",
                  position = {3, 0.200000002980232, -1.2}, width = 300, height = 350, font_size = 200,
                  tooltip = "Move Forwards",
                  color = {1, 1, 0},
                  font_color = {0, 0, 0}
              })
              self.createButton({
                  click_function = "moveBackwards",
                  function_owner = self,
                  label = "B",
                  position = {3.8, 0.2, -1.2}, width = 300, height = 350, font_size = 200,
                  tooltip = "Move Backwards",
                  color = {1, 1, 0},
                  font_color = {0, 0, 0}
              })
              self.createButton({
                  click_function = "moveLeft",
                  function_owner = self,
                  label = "L",
                  position = {4.6, 0.2, -1.2}, width = 300, height = 350, font_size = 200,
                  tooltip = "Strafe Left",
                  color = {1, 1, 0},
                  font_color = {0, 0, 0}
              })
              self.createButton({
                  click_function = "moveRight",
                  function_owner = self,
                  label = "R",
                  position = {5.4, 0.2, -1.2}, width = 300, height = 350, font_size = 200,
                  tooltip = "Strafe Right",
                  color = {1, 1, 0},
                  font_color = {0, 0, 0}
              })

        else
              self.createButton({
                  click_function = "moveBackwards",
                  function_owner = self,
                  label = "B",
                  position = {3, 0.200000002980232, -1.2}, width = 300, height = 350, font_size = 200,
                  tooltip = "Move Backwards",
                  color = {1, 1, 0},
                  font_color = {0, 0, 0}
              })

              if moveDirection == "backward" then
                  self.editButton({
                      index = 13,
                      click_function = "moveForward",
                      label = "F",
                      tooltip = "Move Forwards"
                  })
              end
        end



    end

    self.createButton({
        click_function = "moveFull",
        function_owner = self,
        label = "FULL",
        position = {4.2, 0.2, 1.2}, width = 700, height = 350, font_size = 200, color = {0, 0, 0, 1}, font_color = {0.0551, 0.9312, 0, 1},
        tooltip = "Execute Full Move"
    })


    self.createButton({
        click_function = "moveStart",
        function_owner = self,
        label = "START",
        position = {4.2, 0.2, 0.4}, width = 700, height = 350, font_size = 200, color = {0, 0, 0, 1}, font_color = {0, 0.9294, 0.8752, 1},
        tooltip = "Move back to start position"
    })

end
------------------------------------------------- MOVE BACK------------------------------------------------------------

function moveFull()
    if templateB then
        local startPos = templateB.getPosition()
        local startRot = templateB.getRotation()
        local endOffset = unitData.baseSize == "small" and templateInfo.deployMod.small or 0.0
        local endPos = translatePos(startPos, startRot, unitData.aStart + endOffset, 0)
        endPos.y = endPos.y + 2

        local endRot = startRot
        if moveDirection == "backward" then
            endRot.y = endRot.y + 180
        elseif moveDirection == "left" then
            endRot.y = endRot.y + 90
        elseif moveDirection == "right" then
            endRot.y = endRot.y - 90
        end

        selectedUnitObj.setPositionSmooth(endPos, false, false)
        selectedUnitObj.setRotationSmooth(startRot, false, false)
        Wait.frames(function()
          selectedUnitObj.call("checkVelocity")
        end)
    end
end


function moveStart()
    local endPos = initPos
    endPos.y = initPos.y + 2
    selectedUnitObj.setPositionSmooth(endPos, false, false)
    selectedUnitObj.setRotationSmooth(initRot, false, false)
    Wait.frames(function()
        selectedUnitObj.call("checkVelocity")
    end)
end

function moveBackwards()
    self.editButton({
        index = 11,
        click_function = "moveForward",
        label = "F",
        tooltip = "Move Forwards"
    })
    moveDirection = "backward"
    moveUnit()
end

function moveForward()
    self.editButton({
        index = 11,
        click_function = "moveBackwards",
        label = "B",
        tooltip = "Move Backwards"
    })
    moveDirection = "forward"
    moveUnit()
end

function moveLeft()
    moveDirection = "left"
    moveUnit()
end

function moveRight()
    moveDirection = "right"
    moveUnit()
end

------------------------------------------------- stop UNIT ------------------------------------------------------------
function stopUnit()
    -- destroy templates
    selectedUnitObj.call("printMovement")
    selectedUnitObj.call("setStartPos")
    self.clearButtons()
    clearTemplates()
    resetButtons()
    unhighlightEnemies()
    unlockAllUnits("MoveInProgress")
end

------------------------------------------------- Clear templates------------------------------------------------------------
function clearTemplates()
    clearMovementTemplates()
    -- Iron Squadron overlays (see !/IsqOverlays): clearRangeRulers only wipes
    -- the vanilla ruler, so ours has to be cleared alongside it. No-op when the
    -- overlays are off, which is the default.
    isqOrderClearRange()
    clearRangeRulers()
    clearCohesionRulers()
end

function clearMovementTemplates()
    if templateA ~= nil then
        destroyObject(templateA)
    end
    if templateB ~= nil then
        destroyObject(templateB)
    end
    if maxMoveTemplate ~= nil then
        -- pcall : l'objet peut avoir deja disparu (Clear Map, standbyTokens),
        -- auquel cas destroyObject leve et le reste du nettoyage sautait.
        pcall(destroyObject, maxMoveTemplate)
        maxMoveTemplate = nil
    end
end

function clearCohesionRulers()
    if selectedUnitObj then
        selectedUnitObj.setVar("moveState", false)
        selectedUnitObj.call("clearCohesionRuler")
    end
end

function clearAttackLine()
    -- Any verdict still computing is now stale: the coroutine checks the
    -- generation at every resume point and bows out.
    losGeneration = (losGeneration or 0) + 1
    losBarHide()
    Global.setVectorLines({})
    if losSilhouetteGUIDs then
        for _, guid in pairs(losSilhouetteGUIDs) do
            local leader = getObjectFromGUID(guid)
            -- Only lower a silhouette that is still up: the player may have
            -- toggled it off themselves mid-attack.
            if leader ~= nil and leader.getVar("silhouetteState") then
                leader.call("clearSilhouette")
            end
        end
        losSilhouetteGUIDs = nil
    end
end


------------------------------------------------- CHANGESPEED------------------------------------------------------------
function changeSpeed1()
    unitData.selectedSpeed = 1
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end

function changeSpeed2()
    unitData.selectedSpeed = 2
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end

function changeSpeed3()
    unitData.selectedSpeed = 3
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end
------------------------------------------------- AIM------------------------------------------------------------
function aim()
    basePos = selectedUnitObj.getPosition()
    baseRot = selectedUnitObj.getRotation()

    local q = math.rad(baseRot.y)
    local a = 1 * math.cos(q)
    local b = 1 * math.sin(q)

    local tokenPosition = {basePos.x + b, basePos.y + 1, basePos.z + a}
    local tokenRotation = {0, baseRot.y, 0}

    aimBag = getObjectFromGUID(Global.getVar("aimBagGUID"))
    aimBag.takeObject({
        position = tokenPosition,
        rotation = tokenRotation
    })

end

------------------------------------------------- dodge------------------------------------------------------------
function dodge()
    basePos = selectedUnitObj.getPosition()
    baseRot = selectedUnitObj.getRotation()

    local q = math.rad(baseRot.y + 50)
    local a = 1 * math.cos(q)
    local b = 1 * math.sin(q)

    local tokenPosition = {basePos.x + b, basePos.y + 1, basePos.z + a}
    local tokenRotation = {0, baseRot.y - 30, 0}

    aimBag = getObjectFromGUID(Global.getVar("dodgeBagGUID"))
    aimBag.takeObject({
        position = tokenPosition,
        rotation = tokenRotation
    })

end

------------------------------------------------- overwatch------------------------------------------------------------
function overwatch()
    basePos = selectedUnitObj.getPosition()
    baseRot = selectedUnitObj.getRotation()

    local q = math.rad(baseRot.y - 50)
    local a = 1 * math.cos(q)
    local b = 1 * math.sin(q)

    local tokenPosition = {basePos.x + b, basePos.y + 1, basePos.z + a}
    local tokenRotation = {0, baseRot.y, 0}

    aimBag = getObjectFromGUID(Global.getVar("standbyBagGUID"))
    aimBag.takeObject({
        position = tokenPosition,
        rotation = tokenRotation
    })

end

------------------------------------------------- surge------------------------------------------------------------
function surge()
    basePos = selectedUnitObj.getPosition()
    baseRot = selectedUnitObj.getRotation()

    local q = math.rad(baseRot.y - 50)
    local a = 1 * math.cos(q)
    local b = 1 * math.sin(q)

    local tokenPosition = {basePos.x + b, basePos.y + 1, basePos.z + a}
    local tokenRotation = {0, baseRot.y, 0}

    aimBag = getObjectFromGUID(Global.getVar("surgeBagGUID"))
    aimBag.takeObject({
        position = tokenPosition,
        rotation = tokenRotation
    })

end


------------------------------------------------- attack------------------------------------------------------------
function attack()
    clearTemplates()
    resetButtons()
    self.editButton({
        index = 3,
        click_function = "stopAttack",
        function_owner = self,
        label = "     DONE",
        color = {0.7, 0.03, 0.03},
        font_color = {1, 2, 1}
    })
    attackMode()
end

-- Iron Squadron overlays (see !/IsqOverlays): draw and clear this token's range
-- with the Projector renderer when they are on. Both are no-ops when they are
-- off, which is the default, so the vanilla calls around them are untouched.
--
-- These two only ever call into the module. The vanilla spawnRangeRuler and
-- clearRangeRulers are deliberately NOT overridden on this object: doing so
-- crashed Tabletop Simulator on macOS whenever a figure hotkey spawned a range
-- bundle, so only their callers are adapted.
function isqOrderSpawnRange()
    if not selectedUnitObj then return end
    if not isqOverlaysOn() then return end
    -- Clear before triggering: the module toggles by GUID and the hover hotkey
    -- writes to this same unit, so without the clear a click meant to draw
    -- could erase instead.
    isqClearRange({figGUID = selectedUnitObj.getGUID()})
    isqRangeTrigger({figGUID = selectedUnitObj.getGUID()})
end

function isqOrderClearRange()
    if not selectedUnitObj then return end
    if not isqOverlaysOn() then return end
    isqClearRange({figGUID = selectedUnitObj.getGUID()})
end

function targetingMode()
    if not enemyHighlighted then
        exitAttackMode()
        highlightEnemies()
        if isqOverlaysOn() then
            isqOrderSpawnRange()
        else
            spawnRangeRuler(selectedUnitObj)
        end
        enemyHighlighted = true
        resetRangeButtons()
    else
        exitTargetingMode()
    end
end

function attackMode()
    if not attackModeOn then
        exitTargetingMode()
        highlightEnemies()
        if isqOverlaysOn() then
            isqOrderSpawnRange()
        else
            spawnRangeRuler(selectedUnitObj)
        end
        attackModeOn = true
        resetTargetingButtons()
    else
        exitTargetingMode()
    end
end

function exitTargetingMode()
    enemyHighlighted = false
    attackModeOn = false
    isqOrderClearRange()
    clearRangeRulers()
    unhighlightEnemies()
    clearAttackLine()
end

function exitAttackMode()
    enemyHighlighted = false
    attackModeOn = false
    isqOrderClearRange()
    clearRangeRulers()
    unhighlightEnemies()
end

function resetRangeButtons()
    enemyLeaders = getEnemyUnits()

    for _, leader in pairs(enemyLeaders) do
        createRangeButton(leader)
    end
end

function resetTargetingButtons()
    enemyLeaders = getEnemyUnits()

    for _, leader in pairs(enemyLeaders) do
        createAttackButton(leader)
        createRangeButton(leader)
    end
end

function attackMenu(attackTargetObj)
    unhighlightEnemies()
    highlightEnemy(attackTargetObj)
    clearRangeRulers()
    -- Switching targets goes through here again: drop the previous target's
    -- beams and silhouettes before drawing the new ones.
    clearAttackLine()

    -- this used to be configurable per unit type, which meant that we made the
    -- ion/wound/suppression buttons vertically higher to make up for variable
    -- height minis.
    --
    -- it's possible we can use the actual collider height of the mini in the
    -- future in order to tune this.
    local buttonHeight = attackTargetObj.getVar("height") or 2


    _G["addIon"..self.getGUID()] = function() addIon(attackTargetObj) end
    _G["addWound"..self.getGUID()] = function() addWound(attackTargetObj) end
    _G["addSuppression"..self.getGUID()] = function() addSuppression(attackTargetObj) end

    attackTargetObj.createButton({
        click_function = "addIon"..self.getGUID(), function_owner = self, label = "I", position = {-0.9, buttonHeight, 0}, rotation = {0, 180, 0}, scale = {0.5, 0.5, 0.5}, width = 700, height = 700, font_size = 500, color = {0, 0.1711, 1, 1}, tooltip = "I"
    })
    attackTargetObj.createButton({
        click_function = "addWound"..self.getGUID(), function_owner = self, label = "W", position = {0.9, buttonHeight, 0}, rotation = {0, 180, 0}, scale = {0.5, 0.5, 0.5}, width = 700, height = 700, font_size = 500, color = {1, 0, 0, 1}, tooltip = "W"
    })
    attackTargetObj.createButton({
        click_function = "addSuppression"..self.getGUID(), function_owner = self, label = "S", position = {0, buttonHeight, 0}, rotation = {0, 180, 0}, scale = {0.5, 0.5, 0.5}, width = 700, height = 700, font_size = 500, color = {1, 0.8723, 0, 1}, tooltip = "S"
    })

    -- For every defending mini, draw the two witness lines (one clear of
    -- terrain, one crossing it) in the background; the players judge line of
    -- sight and cover themselves. Silhouettes rise when the rays are done.
    computeLosVerdicts(attackTargetObj)
end

function addSuppression(selectedSuppressionObj)
    local suppressionPos = selectedSuppressionObj.getPosition()
    suppressionPos.y = suppressionPos.y + 1
    suppressionBag = getObjectFromGUID(Global.getVar("suppressionBagGUID"))
    suppressionBag.takeObject({
        position = suppressionPos,
        rotation = selectedSuppressionObj.getRotation()
    })
end

function addWound(selectedWoundObj)
    local woundPos = selectedWoundObj.getPosition()
    woundPos.y = woundPos.y + 1
    woundBag = getObjectFromGUID(Global.getVar("woundBagGUID"))

    woundPos = translatePos(woundPos,selectedWoundObj.getRotation(),1, 0)

    woundBag.takeObject({
        position = woundPos,
        rotation = selectedWoundObj.getRotation()
    })
end

function addIon(selectedIonObj)
    local ionPos = selectedIonObj.getPosition()
    ionPos.y = ionPos.y + 1
    ionBag = getObjectFromGUID(Global.getVar("ionBagGUID"))

    ionPos = translatePos(ionPos,selectedIonObj.getRotation(),1, 180)

    ionBag.takeObject({
        position = ionPos,
        rotation = selectedIonObj.getRotation()
    })
end

-- The silhouette a mini is judged by: a cylinder standing on its base, as wide
-- as the base and as tall as its unit's silhouette. Base size and custom
-- silhouettes live on the unit leader, not on each mini, so that is who gets
-- asked. Same rules Unit_Leader uses to spawn the visible ones, so the beams
-- line up with what SIL draws.
function silhouetteOf(leaderObj)
    local leaderData = leaderObj.getTable("unitData")
    local baseSize = (leaderData and leaderData.baseSize) or "small"
    local radius = (templateInfo.baseRadius[baseSize] or templateInfo.baseRadius.small) / 2
    local height = templateInfo.silhouetteHeight.small
    local offset = 0

    if leaderObj.getVar("silhType") == "custom" then
        height = leaderObj.getVar("silhHeight") or templateInfo.silhouetteHeight.custom
        offset = leaderObj.getVar("silhOffset") or 0
    elseif baseSize ~= "small" then
        height = templateInfo.silhouetteHeight.notched
    end

    return radius, height, offset
end

------------------------------------------------- LIGNE DE VUE ------------------------------------------------------------
-- The tool shows evidence, the players make the ruling. For each defending
-- mini it draws up to two lines from the attacking leader's silhouette to
-- that mini's silhouette: a green one that crosses no terrain, and a red one
-- that does. Line of sight and cover are then judged by eye, at the table,
-- exactly like the rule intends -- nothing is decided by the mod.

-- Time budget per frame: the search yields as soon as it has eaten its
-- slice of the frame, however many rays that was -- box rays are cheap,
-- mesh rays are not, the clock does not care. Twelve milliseconds trades a
-- little frame rate during a long verdict for half the wall-clock wait.
local LOS_FRAME_BUDGET = 0.012
-- Printed with every attack so a play test can never run an older build
-- unnoticed (the save-patching workflow makes that mistake silent). Bump it
-- with every LoS change.
local LOS_BUILD = "v23"
-- Console summaries. Cut to false for a release build: the engine stays
-- silent and only the witness lines speak.
local LOS_DEBUG = false

local function losLog(msg)
    if LOS_DEBUG then print("[ISQ LDV] " .. msg) end
end

-- The progress rule along the top of the screen (isqProgressRule in the
-- Global XML, the same band every loading indicator of the mod uses), so a
-- long pass visibly keeps working.
function losBarSet(pct)
    pcall(function()
        UI.setAttribute("isqProgressRuleFill", "width", math.floor(pct) .. "%")
        UI.setAttribute("isqProgressRule", "active", "true")
    end)
end

function losBarHide()
    pcall(function() UI.setAttribute("isqProgressRule", "active", "false") end)
end

losGeneration = 0
losCtx = nil
losFrameStart = 0

-- Sample points refine level by level, the way a render sharpens: a narrow
-- sight gap the coarse grid misses is caught by the finer passes, without
-- ever paying the full grid on an open shot. Azimuths spread over the
-- facing half of the contour, heights over the whole silhouette; each
-- coordinate carries the level it first appears at, and a pair of points is
-- cast exactly once, at the level its newest point joins. Level 1 is a 3x3
-- grid per silhouette; level 4 reaches 81 points per silhouette, more than
-- six thousand pairs, but the search still stops at the first witnesses.
local LOS_AZIMUTHS = {
    {0, 1}, {-90, 1}, {90, 1},
    {-45, 2}, {45, 2},
    {-22.5, 3}, {22.5, 3}, {-67.5, 3}, {67.5, 3},
}
-- Heights and radius sample the EXACT silhouette contour: the rule judges
-- silhouette to silhouette, and a sliver of visibility hugging the top or
-- the side edge lives precisely in the last percents. The old 0.95/0.97
-- insets were Physics.cast-era self-hit protection and ate those slivers.
-- Mid height leads: the first clear line found is the one drawn, and a
-- waist-high witness reads well on the table where a ground-level one
-- drowns in the terrain. The top stays at the exact silhouette summit --
-- that is the extreme players hunt lines with -- but the bottom stops a
-- twentieth short: terrain meshes are not sealed against the bumpy ground,
-- and a true base-level ray sneaks UNDER a rock's skirt and comes out
-- "clear" through what the eye reads as solid stone.
local LOS_HEIGHTS = {
    {0.5, 1}, {1.0, 1}, {0.05, 1},
    {0.25, 2}, {0.75, 2},
    {0.125, 4}, {0.375, 4}, {0.625, 4}, {0.875, 4},
}
local LOS_MAX_LEVEL = 4

function losSamplePoints(obj, leaderObj, towardPos)
    local radius, height, offset = silhouetteOf(leaderObj)
    local p = obj.getPosition()
    local baseY = p.y + offset
    local dx, dz = towardPos.x - p.x, towardPos.z - p.z
    local g = math.sqrt(dx * dx + dz * dz)
    if g < 0.001 then dx, dz, g = 1, 0, 1 end
    dx, dz = dx / g, dz / g
    local r = radius
    local points = {}
    for _, az in ipairs(LOS_AZIMUTHS) do
        local a = math.rad(az[1])
        local c, s = math.cos(a), math.sin(a)
        local ux, uz = dx * c - dz * s, dx * s + dz * c
        for _, hf in ipairs(LOS_HEIGHTS) do
            table.insert(points, {
                x = p.x + ux * r,
                y = baseY + height * hf[1],
                z = p.z + uz * r,
                lvl = math.max(az[2], hf[2]),
            })
        end
    end
    return points
end

-- Only the boxes standing near this defender's corridor concern its rays:
-- with a table of scenery, the filter cuts every cast from dozens of slab
-- tests to a handful. Judged flat, from the box's worst reach (half
-- diagonal plus its center offset) against the attacker-defender segment,
-- padded by how far the sample points stray from the centers.
function losCorridorObbs(ctx, defPos, pad)
    local ax, az = ctx.leaderPos.x, ctx.leaderPos.z
    local dx, dz = defPos.x - ax, defPos.z - az
    local len2 = dx * dx + dz * dz
    local kept = {}
    for _, obb in ipairs(ctx.obbs) do
        local bx, bz = obb.pos.x - ax, obb.pos.z - az
        local t = 0
        if len2 > 0.000001 then
            t = math.max(0, math.min(1, (bx * dx + bz * dz) / len2))
        end
        local ex, ez = bx - t * dx, bz - t * dz
        local reach = obb.reach + pad
        if ex * ex + ez * ez <= reach * reach then
            table.insert(kept, obb)
        end
    end
    return kept
end

-- Does a segment cross the silhouette cylinder of a third-party ground
-- vehicle? Pure arithmetic, no physics call: a quadratic in the ground
-- plane, then a height window over the crossed interval.
function losSegmentHitsCylinder(p, q, cyl)
    local dx, dz = q.x - p.x, q.z - p.z
    local fx, fz = p.x - cyl.x, p.z - cyl.z
    local a = dx * dx + dz * dz
    local t0, t1
    if a < 0.000001 then
        if fx * fx + fz * fz > cyl.r * cyl.r then return false end
        t0, t1 = 0, 1
    else
        local b = 2 * (fx * dx + fz * dz)
        local c = fx * fx + fz * fz - cyl.r * cyl.r
        local disc = b * b - 4 * a * c
        if disc <= 0 then return false end
        local s = math.sqrt(disc)
        t0 = math.max((-b - s) / (2 * a), 0)
        t1 = math.min((-b + s) / (2 * a), 1)
        if t0 > t1 then return false end
    end
    local ya = p.y + (q.y - p.y) * t0
    local yb = p.y + (q.y - p.y) * t1
    return math.max(ya, yb) >= cyl.y0 and math.min(ya, yb) <= cyl.y1
end

-- What counts as terrain for a ray: not a mini (minis only block through the
-- ground-vehicle cylinders), not a game aid, not something tiny. The rest of
-- the scenery does.
function losIsTerrain(ctx, o)
    if ctx.miniGuids[o.getGUID()] then return false end
    if o.getVar("isAMini") == true then return false end
    -- Asset bundles are game aids here, never terrain: silhouettes, smoke,
    -- rulers, effects. The map's terrain pieces are all Custom_Model. A
    -- raised silhouette especially must not block the very rays it frames.
    -- (.name is the internal type name; .type can report plain "Generic".)
    if o.name == "Custom_Assetbundle" then return false end
    local t = o.type
    if t == "Card" or t == "Deck" or t == "Die" or t == "Bag" or t == "Infinite" then
        return false
    end
    -- Zones have bounds but nothing to see: scripting and hand zones, fog,
    -- randomize and layout zones would otherwise become empty boxes that every
    -- corridor ray has to test.
    if t == "Scripting" or t == "Hand" or t == "FogOfWar" or t == "Randomize" or t == "Layout" then
        return false
    end
    local name = string.lower(o.getName() or "")
    -- The table and the battlefield board are not terrain: everything rests
    -- on them, so they always touch the attacker and only add noise.
    if name == "table" or name == "battlefield" then
        return false
    end
    -- The map annotates its pieces: anything tagged [No Cover] (landing
    -- platforms, decorative floors) never blocks sight -- that is also what
    -- lets a unit standing on such a piece shoot off it freely.
    if string.find(name, "no cover") then
        return false
    end
    if string.find(name, "token") or string.find(name, "ruler")
        or string.find(name, "template") or string.find(name, "dice")
        or string.find(name, "silhouette") or string.find(name, "objective") then
        return false
    end
    local b = o.getBounds()
    if b and b.size.x < 1.2 and b.size.z < 1.2 and b.size.y < 0.8 then
        return false
    end
    return true
end

-- The oriented visual box of a terrain piece: its renderer bounds at zero
-- rotation (so, the VISUAL mesh, never the collider -- terrain colliders in
-- this mod can be flat resting plates a few hundredths tall) plus enough of
-- the piece's rotation to test rays in its local frame.
function losMakeObb(obj)
    -- getVisualBoundsNormalized, NOT getBoundsNormalized: the plain one
    -- measures the COLLIDER (a barricade's came back 0.06 tall, its resting
    -- plate), the visual one measures the renderers the players see.
    local b = obj.getVisualBoundsNormalized()
    local p = obj.getPosition()
    local r = obj.getRotation()
    local s = obj.getScale()
    -- The visual mesh URL feeds the triangle pass: every Custom_Model's OBJ
    -- is right there in its data, so any terrain piece, present or future,
    -- is covered with no per-map bookkeeping.
    local url = nil
    if obj.name == "Custom_Model" then
        local ok, co = pcall(function() return obj.getCustomObject() end)
        if ok and co ~= nil then url = co.mesh end
    end
    local rx, ry, rz = math.rad(r.x), math.rad(r.y), math.rad(r.z)
    -- Rotations precomputed once: these cosines serve tens of thousands
    -- of times per verdict and are never recomputed in the hot loops.
    return {
        name = obj.getName() or "?",
        pos = p,
        cosy = math.cos(ry), siny = math.sin(ry),
        cosx = math.cos(rx), sinx = math.sin(rx),
        cosz = math.cos(rz), sinz = math.sin(rz),
        scx = (s.x ~= 0 and s.x or 1),
        scy = (s.y ~= 0 and s.y or 1),
        scz = (s.z ~= 0 and s.z or 1),
        center = {x = b.center.x - p.x, y = b.center.y - p.y, z = b.center.z - p.z},
        half = {x = b.size.x / 2, y = b.size.y / 2, z = b.size.z / 2},
        -- How far from its position the box can reach, in any direction:
        -- the corridor test needs it once per box and per defender.
        reach = math.sqrt(b.size.x ^ 2 + b.size.y ^ 2 + b.size.z ^ 2) / 2
            + math.sqrt((b.center.x - p.x) ^ 2 + (b.center.y - p.y) ^ 2 + (b.center.z - p.z) ^ 2),
        url = url,
    }
end

-- World point -> the box's local frame. Unity composes rotations as
-- yaw(Y) * pitch(X) * roll(Z), so the inverse unwinds yaw, pitch, roll.
-- Value in, values out: no table allocation on the hot path.
function losToObbFrame(obb, wx, wy, wz)
    local x, y, z = wx - obb.pos.x, wy - obb.pos.y, wz - obb.pos.z
    local c, s = obb.cosy, obb.siny
    x, z = x * c - z * s, x * s + z * c
    c, s = obb.cosx, obb.sinx
    y, z = y * c + z * s, -y * s + z * c
    c, s = obb.cosz, obb.sinz
    x, y = x * c + y * s, -x * s + y * c
    return x, y, z
end

-- Segment against the oriented visual box: slab test in the box's local
-- frame. Purely geometric -- what the players see is what blocks, and
-- shooting over your own barricade works because the high silhouette
-- points genuinely clear its top, not through any forgiveness rule.
-- Returns nil on a miss, or the t interval of the crossing so the triangle
-- pass can clip its work to it.
function losSegmentHitsObb(p, q, obb)
    local lpx, lpy, lpz = losToObbFrame(obb, p.x, p.y, p.z)
    local lqx, lqy, lqz = losToObbFrame(obb, q.x, q.y, q.z)
    local c, h = obb.center, obb.half
    local t0, t1 = 0, 1
    local d = lqx - lpx
    local lo, hi = c.x - h.x, c.x + h.x
    if d < 0.000001 and d > -0.000001 then
        if lpx < lo or lpx > hi then return nil end
    else
        local ta, tb = (lo - lpx) / d, (hi - lpx) / d
        if ta > tb then ta, tb = tb, ta end
        if ta > t0 then t0 = ta end
        if tb < t1 then t1 = tb end
        if t0 > t1 then return nil end
    end
    d = lqy - lpy
    lo, hi = c.y - h.y, c.y + h.y
    if d < 0.000001 and d > -0.000001 then
        if lpy < lo or lpy > hi then return nil end
    else
        local ta, tb = (lo - lpy) / d, (hi - lpy) / d
        if ta > tb then ta, tb = tb, ta end
        if ta > t0 then t0 = ta end
        if tb < t1 then t1 = tb end
        if t0 > t1 then return nil end
    end
    d = lqz - lpz
    lo, hi = c.z - h.z, c.z + h.z
    if d < 0.000001 and d > -0.000001 then
        if lpz < lo or lpz > hi then return nil end
    else
        local ta, tb = (lo - lpz) / d, (hi - lpz) / d
        if ta > tb then ta, tb = tb, ta end
        if ta > t0 then t0 = ta end
        if tb < t1 then t1 = tb end
        if t0 > t1 then return nil end
    end
    return t0, t1
end

---------------------------------------------------------------------------
-- MESH PASS (triangle precision). The visual box over-blocks by
-- construction: a green from the box pass is therefore CERTAIN, but its
-- absence may be a false negative -- the narrow angle passes through the
-- empty part of a box (a building corner, under an antenna). In that one
-- case a second pass replays the same rays against the REAL triangles of
-- the visual mesh, downloaded once per piece type (WebRequest on the OBJ
-- URL the map declares), so every present or future terrain piece is
-- covered by the map itself, not by a table kept by hand.
---------------------------------------------------------------------------
losMeshCache = {}
local LOS_MESH_MAX_TRIS = 25000
local LOS_MESH_MAX_RAYS = 8000
local LOS_MESH_GRID = 16

function losMeshRequest(url)
    local entry = losMeshCache[url]
    if entry ~= nil then return entry end
    entry = {status = "loading"}
    losMeshCache[url] = entry
    WebRequest.get(url, function(req)
        if entry.status ~= "loading" then return end
        if req.is_error or req.text == nil or #req.text == 0 then
            entry.status = "failed"
        else
            entry.text = req.text
            entry.status = "raw"
        end
    end)
    return entry
end

-- Budgeted OBJ parse, run inside the verdict coroutine: a few thousand
-- lines per frame. Fan-triangulates polygons, keeps flat arrays (vertex,
-- edges, box) per triangle plus a 16x16 XZ grid for the ray broad phase.
-- Returns false if the generation moved on mid-parse (state rewinds to raw
-- so the next attack picks the text back up).
function losMeshParse(entry)
    entry.status = "parsing"
    local vx, vy, vz = {}, {}, {}
    local T = {ax = {}, ay = {}, az = {}, e1x = {}, e1y = {}, e1z = {},
               e2x = {}, e2y = {}, e2z = {},
               minx = {}, maxx = {}, miny = {}, maxy = {}, minz = {}, maxz = {}}
    local n = 0
    local lines = 0
    local myGen = losGeneration
    for line in string.gmatch(entry.text, "[^\r\n]+") do
        local head = string.sub(line, 1, 2)
        if head == "v " then
            local a, b, c = string.match(line, "^v%s+(%S+)%s+(%S+)%s+(%S+)")
            if a ~= nil then
                table.insert(vx, tonumber(a))
                table.insert(vy, tonumber(b))
                table.insert(vz, tonumber(c))
            end
        elseif head == "f " then
            local idx = {}
            for tok in string.gmatch(line, "%S+") do
                local i = string.match(tok, "^(%-?%d+)")
                if i ~= nil then
                    i = tonumber(i)
                    if i < 0 then i = #vx + i + 1 end
                    table.insert(idx, i)
                end
            end
            for k = 2, #idx - 1 do
                local i1, i2, i3 = idx[1], idx[k], idx[k + 1]
                if vx[i1] and vx[i2] and vx[i3] then
                    n = n + 1
                    T.ax[n], T.ay[n], T.az[n] = vx[i1], vy[i1], vz[i1]
                    T.e1x[n] = vx[i2] - vx[i1]
                    T.e1y[n] = vy[i2] - vy[i1]
                    T.e1z[n] = vz[i2] - vz[i1]
                    T.e2x[n] = vx[i3] - vx[i1]
                    T.e2y[n] = vy[i3] - vy[i1]
                    T.e2z[n] = vz[i3] - vz[i1]
                    T.minx[n] = math.min(vx[i1], vx[i2], vx[i3])
                    T.maxx[n] = math.max(vx[i1], vx[i2], vx[i3])
                    T.miny[n] = math.min(vy[i1], vy[i2], vy[i3])
                    T.maxy[n] = math.max(vy[i1], vy[i2], vy[i3])
                    T.minz[n] = math.min(vz[i1], vz[i2], vz[i3])
                    T.maxz[n] = math.max(vz[i1], vz[i2], vz[i3])
                end
            end
            if n > LOS_MESH_MAX_TRIS then
                entry.status = "toobig"
                entry.text = nil
                return true
            end
        end
        lines = lines + 1
        if lines % 400 == 0 and os.clock() - losFrameStart > LOS_FRAME_BUDGET then
            coroutine.yield(0)
            losFrameStart = os.clock()
            if losGeneration ~= myGen then
                entry.status = "raw"
                return false
            end
        end
    end
    if n == 0 then
        entry.status = "failed"
        entry.text = nil
        return true
    end
    -- XZ grid of the triangles, so each ray only visits a few cells.
    local gx0, gx1 = math.huge, -math.huge
    local gz0, gz1 = math.huge, -math.huge
    for i = 1, n do
        gx0 = math.min(gx0, T.minx[i]); gx1 = math.max(gx1, T.maxx[i])
        gz0 = math.min(gz0, T.minz[i]); gz1 = math.max(gz1, T.maxz[i])
    end
    local cw = math.max((gx1 - gx0) / LOS_MESH_GRID, 0.0001)
    local ch = math.max((gz1 - gz0) / LOS_MESH_GRID, 0.0001)
    local grid = {}
    for i = 1, n do
        local cx0 = math.floor((T.minx[i] - gx0) / cw)
        local cx1 = math.floor((T.maxx[i] - gx0) / cw)
        local cz0 = math.floor((T.minz[i] - gz0) / ch)
        local cz1 = math.floor((T.maxz[i] - gz0) / ch)
        for cx = math.max(cx0, 0), math.min(cx1, LOS_MESH_GRID - 1) do
            for cz = math.max(cz0, 0), math.min(cz1, LOS_MESH_GRID - 1) do
                local key = cx * LOS_MESH_GRID + cz + 1
                if grid[key] == nil then grid[key] = {} end
                table.insert(grid[key], i)
            end
        end
        if i % 400 == 0 and os.clock() - losFrameStart > LOS_FRAME_BUDGET then
            coroutine.yield(0)
            losFrameStart = os.clock()
            if losGeneration ~= myGen then
                entry.status = "raw"
                return false
            end
        end
    end
    entry.tris = T
    entry.n = n
    entry.grid = grid
    entry.gx0, entry.gz0, entry.cw, entry.ch = gx0, gz0, cw, ch
    entry.text = nil
    entry.status = "ready"
    return true
end

-- Does the segment hit an actual triangle of the piece? Works in the OBJ's
-- local, unscaled frame; clipped to the box-crossing interval; the XZ grid
-- then per-triangle boxes cut the Moller-Trumbore tests to a handful.
function losMeshBlocks(obb, entry, p, q, t0, t1)
    local lpx, lpy, lpz = losToObbFrame(obb, p.x, p.y, p.z)
    local lqx, lqy, lqz = losToObbFrame(obb, q.x, q.y, q.z)
    lpx, lpy, lpz = lpx / obb.scx, lpy / obb.scy, lpz / obb.scz
    lqx, lqy, lqz = lqx / obb.scx, lqy / obb.scy, lqz / obb.scz
    local ta = math.max(0, t0 - 0.02)
    local tb = math.min(1, t1 + 0.02)
    local ox = lpx + (lqx - lpx) * ta
    local oy = lpy + (lqy - lpy) * ta
    local oz = lpz + (lqz - lpz) * ta
    local dx = lpx + (lqx - lpx) * tb - ox
    local dy = lpy + (lqy - lpy) * tb - oy
    local dz = lpz + (lqz - lpz) * tb - oz
    local sminx, smaxx = math.min(ox, ox + dx), math.max(ox, ox + dx)
    local sminy, smaxy = math.min(oy, oy + dy), math.max(oy, oy + dy)
    local sminz, smaxz = math.min(oz, oz + dz), math.max(oz, oz + dz)
    local T = entry.tris
    local cx0 = math.max(math.floor((sminx - entry.gx0) / entry.cw), 0)
    local cx1 = math.min(math.floor((smaxx - entry.gx0) / entry.cw), LOS_MESH_GRID - 1)
    local cz0 = math.max(math.floor((sminz - entry.gz0) / entry.ch), 0)
    local cz1 = math.min(math.floor((smaxz - entry.gz0) / entry.ch), LOS_MESH_GRID - 1)
    for cx = cx0, cx1 do
        for cz = cz0, cz1 do
            local cell = entry.grid[cx * LOS_MESH_GRID + cz + 1]
            if cell ~= nil then
                for _, i in ipairs(cell) do
                    if not (T.maxx[i] < sminx or T.minx[i] > smaxx
                        or T.maxy[i] < sminy or T.miny[i] > smaxy
                        or T.maxz[i] < sminz or T.minz[i] > smaxz) then
                        local pvx = dy * T.e2z[i] - dz * T.e2y[i]
                        local pvy = dz * T.e2x[i] - dx * T.e2z[i]
                        local pvz = dx * T.e2y[i] - dy * T.e2x[i]
                        local det = T.e1x[i] * pvx + T.e1y[i] * pvy + T.e1z[i] * pvz
                        if det > 0.000000001 or det < -0.000000001 then
                            local inv = 1 / det
                            local tvx = ox - T.ax[i]
                            local tvy = oy - T.ay[i]
                            local tvz = oz - T.az[i]
                            local u = (tvx * pvx + tvy * pvy + tvz * pvz) * inv
                            if u >= 0 and u <= 1 then
                                local qvx = tvy * T.e1z[i] - tvz * T.e1y[i]
                                local qvy = tvz * T.e1x[i] - tvx * T.e1z[i]
                                local qvz = tvx * T.e1y[i] - tvy * T.e1x[i]
                                local v = (dx * qvx + dy * qvy + dz * qvz) * inv
                                if v >= 0 and u + v <= 1 then
                                    local t = (T.e2x[i] * qvx + T.e2y[i] * qvy + T.e2z[i] * qvz) * inv
                                    if t >= 0 and t <= 1 then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Is this silhouette-to-silhouette line clear? Blocked by the oriented
-- VISUAL box of any terrain piece, or by a third-party ground vehicle
-- silhouette (cylinders). Pure arithmetic, no physics: the mod's terrain
-- colliders do not match what the players see.
function losHitsCylinders(ctx, p, q)
    for _, cyl in ipairs(ctx.blockers) do
        if losSegmentHitsCylinder(p, q, cyl) then return true end
    end
    return false
end

-- A snapshot of the table for one verdict: every mini to ignore in the rays,
-- the silhouette cylinders of third-party ground vehicles (the only minis
-- that block sight), and the defending minis still on the battlefield.
function buildLosContext(attackTargetObj)
    local ctx = {
        gen = losGeneration,
        attackTargetObj = attackTargetObj,
        leaderPos = selectedUnitObj.getPosition(),
        miniGuids = {},
        blockers = {},
        obbs = {},
        defenders = {},
    }
    local zoneObjects = battlefieldZone.getObjects()
    local attackerGUID = selectedUnitObj.getGUID()
    local targetGUID = attackTargetObj.getGUID()
    for _, obj in pairs(zoneObjects) do
        if obj.getVar("isAMini") == true then
            ctx.miniGuids[obj.getGUID()] = true
            local thirdParty = obj.getGUID() ~= attackerGUID and obj.getGUID() ~= targetGUID
            local unitType = obj.getVar("unitType") or ""
            local blocks = thirdParty and string.find(unitType, "Ground Vehicle") ~= nil
            local radius, height, offset = silhouetteOf(obj)
            for _, guid in pairs(obj.getTable("miniGUIDs") or {}) do
                ctx.miniGuids[guid] = true
                if blocks then
                    local m = getObjectFromGUID(guid)
                    if m ~= nil and isMiniOnTable(m, zoneObjects) then
                        local mp = m.getPosition()
                        table.insert(ctx.blockers, {
                            x = mp.x, z = mp.z,
                            y0 = mp.y + offset, y1 = mp.y + offset + height,
                            r = radius,
                        })
                    end
                end
            end
        end
    end
    -- Terrain blocks through its VISUAL oriented box, never its collider:
    -- the mod's terrain colliders can be flat resting plates a few
    -- hundredths tall (a barricade's is), so Physics.cast is blind to what
    -- the players actually see. Swept from the full object list, NOT from
    -- the zone: the zone's trigger misses locked scenery that never moved,
    -- and an empty terrain list blocks nothing at all. A piece counts when
    -- it stands within the battlefield zone's footprint.
    local zonePos = battlefieldZone.getPosition()
    local zoneScale = battlefieldZone.getScale()
    for _, obj in pairs(getAllObjects()) do
        if losIsTerrain(ctx, obj) then
            local p = obj.getPosition()
            if math.abs(p.x - zonePos.x) <= zoneScale.x / 2 + 1
                and math.abs(p.z - zonePos.z) <= zoneScale.z / 2 + 1 then
                table.insert(ctx.obbs, losMakeObb(obj))
            end
        end
    end
    for _, guid in pairs(attackTargetObj.getTable("miniGUIDs") or {}) do
        local m = getObjectFromGUID(guid)
        if m ~= nil and isMiniOnTable(m, zoneObjects) then
            table.insert(ctx.defenders, m)
        end
    end
    if LOS_DEBUG then
        losLog(LOS_BUILD .. " - context: " .. #ctx.blockers
            .. " vehicle cylinder(s), " .. #ctx.obbs .. " terrain box(es), "
            .. #ctx.defenders .. " defender(s)")
    end
    return ctx
end

function computeLosVerdicts(attackTargetObj)
    losGeneration = losGeneration + 1
    losCtx = buildLosContext(attackTargetObj)
    startLuaCoroutine(self, "losVerdictCoroutine")
end

-- For each defending mini, find the two witness lines: the first clear one
-- and the first blocked one, then stop. Open terrain finds its clear line on
-- the very first facing rays; a hidden mini finds its blocked line just as
-- fast. Only the search for a line that does not exist reads every pair.
function losVerdictCoroutine()
    local ctx = losCtx
    local witnesses = {}
    local attackerRadius = silhouetteOf(selectedUnitObj)
    local targetRadius = silhouetteOf(ctx.attackTargetObj)
    local pad = math.max(attackerRadius, targetRadius) + 0.5
    losFrameStart = os.clock()
    for _, def in ipairs(ctx.defenders) do
      -- Handles die between resumes: an attacker deleted mid-verdict ends
      -- it, a defender deleted mid-verdict is simply skipped.
      if selectedUnitObj == nil or selectedUnitObj.isDestroyed() then
        losBarHide()
        return 1
      end
      if def ~= nil and not def.isDestroyed() then
        local defPos = def.getPosition()
        local apts = losSamplePoints(selectedUnitObj, selectedUnitObj, defPos)
        local dpts = losSamplePoints(def, ctx.attackTargetObj, ctx.leaderPos)
        local obbs = losCorridorObbs(ctx, defPos, pad)
        local totalPairs = #apts * #dpts
        local clearLine, blockedLine = nil, nil
        local rays = 0
        local crossedSet = {}
        for level = 1, LOS_MAX_LEVEL do
            for _, ap in ipairs(apts) do
                for _, dp in ipairs(dpts) do
                    if math.max(ap.lvl, dp.lvl) == level then
                        rays = rays + 1
                        local blocked = losHitsCylinders(ctx, ap, dp)
                        -- Every crossed box is recorded, not just the first:
                        -- the triangle pass must know every mesh it may need.
                        for _, obb in ipairs(obbs) do
                            if losSegmentHitsObb(ap, dp, obb) then
                                blocked = true
                                crossedSet[obb] = true
                            end
                        end
                        if not blocked then
                            if clearLine == nil then clearLine = {ap, dp, level} end
                        else
                            if blockedLine == nil then blockedLine = {ap, dp, level} end
                        end
                        if os.clock() - losFrameStart > LOS_FRAME_BUDGET then
                            losBarSet(math.floor(40 * rays / totalPairs))
                            coroutine.yield(0)
                            losFrameStart = os.clock()
                            if ctx.gen ~= losGeneration then losBarHide() return 1 end
                        end
                        if clearLine ~= nil and blockedLine ~= nil then break end
                    end
                end
                if clearLine ~= nil and blockedLine ~= nil then break end
            end
            if clearLine ~= nil and blockedLine ~= nil then break end
        end
        if LOS_DEBUG then
            losLog((def.getName() or "mini") .. " (boxes): "
                .. (clearLine and ("green lvl " .. clearLine[3]) or "NO green") .. ", "
                .. (blockedLine and ("red lvl " .. blockedLine[3]) or "NO red")
                .. " - " .. rays .. " rays, " .. #obbs .. " box(es) in the corridor")
        end

        -- No green from the boxes: the angle may exist in the empty part
        -- of a box. Fine pass against the real triangles, on the crossed
        -- pieces only.
        if clearLine == nil then
            losBarSet(40)
            local needed = {}
            for obb in pairs(crossedSet) do
                if obb.url ~= nil then
                    losMeshRequest(obb.url)
                    table.insert(needed, obb)
                end
            end
            for i, obb in ipairs(needed) do
                local entry = losMeshCache[obb.url]
                local waited = 0
                while entry.status == "loading" and waited < 600 do
                    coroutine.yield(0)
                    losFrameStart = os.clock()
                    waited = waited + 1
                    if ctx.gen ~= losGeneration then losBarHide() return 1 end
                end
                if entry.status == "loading" then entry.status = "failed" end
                if entry.status == "raw" or entry.status == "parsing" then
                    if not losMeshParse(entry) then losBarHide() return 1 end
                end
                if LOS_DEBUG and entry.status == "ready" then
                    losLog("mesh " .. obb.name .. ": "
                        .. entry.n .. " triangles cached")
                end
                losBarSet(40 + math.floor(20 * i / #needed))
            end

            local meshRays = 0
            local meshMax = math.min(totalPairs, LOS_MESH_MAX_RAYS)
            local meshClear, meshRed = nil, nil
            for level = 1, LOS_MAX_LEVEL do
                for _, ap in ipairs(apts) do
                    for _, dp in ipairs(dpts) do
                        if math.max(ap.lvl, dp.lvl) == level then
                            meshRays = meshRays + 1
                            local blocked = losHitsCylinders(ctx, ap, dp)
                            if not blocked then
                                for _, obb in ipairs(obbs) do
                                    local t0, t1 = losSegmentHitsObb(ap, dp, obb)
                                    if t0 ~= nil then
                                        local entry = obb.url ~= nil and losMeshCache[obb.url] or nil
                                        if entry ~= nil and entry.status == "ready" then
                                            if losMeshBlocks(obb, entry, ap, dp, t0, t1) then
                                                blocked = true
                                                break
                                            end
                                        else
                                            -- Mesh unavailable: the box
                                            -- rules, on the safe side.
                                            blocked = true
                                            break
                                        end
                                    end
                                end
                            end
                            if not blocked then
                                meshClear = {ap, dp, level}
                            elseif meshRed == nil then
                                meshRed = {ap, dp, level}
                            end
                            if os.clock() - losFrameStart > LOS_FRAME_BUDGET then
                                losBarSet(60 + math.floor(40 * meshRays / meshMax))
                                coroutine.yield(0)
                                losFrameStart = os.clock()
                                if ctx.gen ~= losGeneration then losBarHide() return 1 end
                            end
                            if meshClear ~= nil then break end
                            if meshRays >= LOS_MESH_MAX_RAYS then break end
                        end
                    end
                    if meshClear ~= nil or meshRays >= LOS_MESH_MAX_RAYS then break end
                end
                if meshClear ~= nil or meshRays >= LOS_MESH_MAX_RAYS then break end
            end
            if meshClear ~= nil then clearLine = meshClear end
            if meshRed ~= nil then blockedLine = meshRed end
            if LOS_DEBUG then
                losLog((def.getName() or "mini") .. " (mesh): "
                    .. (meshClear and ("GREEN lvl " .. meshClear[3]) or "no green") .. ", "
                    .. (meshRed and ("red lvl " .. meshRed[3]) or "no red")
                    .. " - " .. meshRays .. " mesh rays")
            end
        end

        table.insert(witnesses, {clear = clearLine, blocked = blockedLine})
      end
    end
    losBarHide()
    if ctx.gen ~= losGeneration then return 1 end
    drawLosWitnesses(ctx, witnesses)
    return 1
end

-- Green: a line crossing no terrain. Red: a line crossing some. A mini with
-- only a green line is plainly seen, one with only a red line is plainly
-- hidden, and one with both is where the players lean in and judge cover --
-- the mod hands them the two lines the discussion needs, nothing more.
function drawLosWitnesses(ctx, witnesses)
    -- Drawn a hair above their true height: a base-level witness line laid
    -- exactly on the ground is half-buried in the terrain and reads as
    -- missing. The five hundredths match the line's own thickness.
    local function lifted(pt)
        return {x = pt.x, y = pt.y + 0.05, z = pt.z}
    end
    local lines = {}
    for _, w in ipairs(witnesses) do
        if w.clear ~= nil then
            table.insert(lines, {
                points = {lifted(w.clear[1]), lifted(w.clear[2])},
                color = {0.2, 0.9, 0.2},
                thickness = 0.06,
            })
        end
        if w.blocked ~= nil then
            table.insert(lines, {
                points = {lifted(w.blocked[1]), lifted(w.blocked[2])},
                color = {0.9, 0.15, 0.15},
                thickness = 0.06,
            })
        end
    end
    Global.setVectorLines(lines)

    -- Silhouettes only rise HERE, once the rays are done, and only on units
    -- that did not have them up already -- those belong to the player.
    losSilhouetteGUIDs = {}
    for _, leader in ipairs({selectedUnitObj, ctx.attackTargetObj}) do
        if leader ~= nil and not leader.getVar("silhouetteState") then
            leader.call("showSilhouette")
            table.insert(losSilhouetteGUIDs, leader.getGUID())
        end
    end
end

function createAttackButton(leaderObj)
    local buttonHeight = leaderObj.getVar("height") or 2

    _G["attackMenu"..leaderObj.getGUID()] = function() attackMenu(leaderObj) end

    local data = {click_function = "attackMenu"..leaderObj.getGUID(), function_owner = self, label = "ATTACK", position = {0, buttonHeight, -0.9}, rotation = {0, 180, 0}, scale = {0.5, 0.5, 0.5}, width = 1800, height = 700, font_size = 400, color = {1, 0, 0, 1}, font_color = {0, 0, 0, 1}}

    leaderObj.createButton(data)
end

function isMiniOnTable(mini, allUnits)
    for _, check in pairs(allUnits) do
      if check == mini then
        return true
      end
    end
    return false
  end

function createRangeButton(leaderObj)
    local selectedUnitObjUnitName = selectedUnitObj.getVar("unitName")
    local allUnitsOnTable = battlefieldZone.getObjects()
    local enemyBaseSize = leaderObj.getVar("baseSize")
    local enemyMinis = leaderObj.getTable("miniGUIDs")
    local lowestDistance = 99
    for k, guidEntry in pairs(enemyMinis) do
        local obj = getObjectFromGUID(guidEntry)

        if obj and isMiniOnTable(obj, allUnitsOnTable) then
            distance = getDistance(selectedUnitObj, obj)
            if distance < lowestDistance then
                lowestDistance = distance
            end
        end
    end

    -- getDistance mesure de centre a centre, alors qu'en jeu une portee se
    -- mesure de bord de socle a bord de socle. Il faut donc retrancher le rayon
    -- de l'unite qui mesure PUIS celui de la cible. C'est celui de la cible qui
    -- etait retranche deux fois : la bande affichee etait fausse des que les
    -- deux socles differaient, de rayon(cible) - rayon(mesureur), soit jusqu'a
    -- 2,4 pouces entre un trooper et un AAT, sur des bandes de 6.
    -- (templateInfo.baseRadius contient des diametres, d'ou les moities.)
    local ownBaseSize = selectedUnitObj.getVar("baseSize") or unitData.baseSize
    lowestDistance = lowestDistance
        - templateInfo.baseRadius[ownBaseSize]/2
        - templateInfo.baseRadius[enemyBaseSize]/2

    finalRange = math.ceil(lowestDistance/6)
    if finalRange > 4 then
        finalRange = ">4"
    end

    local buttonHeight = leaderObj.getVar("height") or 2
    local data = {click_function = "dud", function_owner = self, label = finalRange, position = {0, buttonHeight, 0}, rotation = {0, 180, 0}, scale = {0.5, 0.5, 0.5}, width = 900, height = 700, font_size = 500, color = {1, 1, 0, 1}, font_color = {0, 0, 0, 1}}

    leaderObj.createButton(data)
end

function dud()
end

function highlightEnemies()
  for _, leader in ipairs(getEnemyUnits()) do
    highlightEnemy(leader)
  end
end

function highlightEnemy(leader)
  local enemyID = leader.getVar("unitID")
  local enemyMinis = leader.getTable("miniGUIDs")
  highlightUnit(enemyMinis, highlightTints[enemyID])
end

function unhighlightEnemies()
  for _, leader in ipairs(getEnemyUnits()) do
    local enemyID = leader.getVar("unitID")
    local enemyMinis = leader.getTable("miniGUIDs")
    unhighlightUnit(enemyMinis)
    leader.call("resetUnitButtons")
  end
end

function getEnemyUnits()
  local miniObjs = {}
  local allUnits = battlefieldZone.getObjects()

  for _, obj in pairs(allUnits) do
    if obj.getVar("isAMini") == true and obj.getVar("colorSide") ~= unitData.colorSide then
      table.insert(miniObjs, obj)
    end
  end

  return miniObjs
end


function stopAttack()
    exitTargetingMode()
    stopUnit()
end


------------------------------------------------- end UNIT ------------------------------------------------------------

function endActivation()
    resetActivation()
    self.flip()
end

function resetActivation()
    stopUnit()
    stopAttack()
    standby()
end

function getDistance(originObj, targetObj)
  local originPos = originObj.getPosition()
  local targetPos = targetObj.getPosition()

  -- set the y-value for each position to 0 to ignore height differences
  originPos:set(nil, 0, nil)
  targetPos:set(nil, 0, nil)
  
  return Vector.distance(originPos, targetPos)
end


function allUnitLeaders()
   local unitLeaders = nil
   unitLeaders = {}
   local leaderCount = 1
   local allUnits = nil
   local allUnits = battlefieldZone.getObjects()

   if allUnits ~= nil then
      for i, unit in pairs(allUnits) do
         local miniData = unit.getTable("unitData")
         local isAMini = unit.getVar("isAMini")
         if miniData and miniData.commandType then
            if isAMini == true then
               unitLeaders[leaderCount] = unit
               leaderCount = leaderCount + 1
            end
         end
      end
   end
   return unitLeaders
end

function lockUnitsExcept(exceptionUnit, lockName)
   local unitLeaders = allUnitLeaders()

   if unitLeaders ~= nil then
      for i, unit in pairs(unitLeaders) do
         if unit ~= exceptionUnit then
            unit.call("tryAddLock", lockName)
         end
      end
   end
end

function unlockAllUnits(lockName)
   local unitLeaders = allUnitLeaders()

   if unitLeaders ~= nil then
      for i, unit in pairs(unitLeaders) do
         unit.call("tryRemoveLock", lockName)
      end
   end
end
