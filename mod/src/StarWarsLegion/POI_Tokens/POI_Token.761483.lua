rangeKey = "poi"

require('!/RangeRulers')

-- each token must define 'rangeKey' with key listed below

-- Token keys in RangeRulers Table
-- smokeToken = 18.8mm diameter (range 1)
-- token = 25.1mm diameter (range 1)
-- poi = 50.8mm diameter (range 0.5 aka 3in)

-- The POI keeps its own copy of the range button (its own position, size and
-- tint) and does not go through !/TokenWithRangeRuler, so it gets the same
-- treatment by hand: one button that follows the visible face, instead of two
-- superposed ones. The helpers come from !/RangeRulers. The look is unchanged:
-- position, width, height, font and tint are kept as they were.
function onLoad()
  rangeOn = false
  createButton({0, 0, 0})
  createButton({0, 0, 180})
  addSilhouetteButton()
end

function onRotate(spin, flip, player_color, old_spin, old_flip)
  isqRefreshButtons(flip)
end

-- onLoad still asks for its two buttons, one per face, exactly as it always
-- did: the first call builds the single reoriented button, the second is a
-- no-op. The requested rotation is ignored, the visible face decides.
local isqRangeButtonBuilt = false
function createButton(rotation)
  if isqRangeButtonBuilt then return end
  isqRangeButtonBuilt = true
  local gameData = getObjectFromGUID(Global.getVar("gameDataGUID"))
  local btnTint = gameData.getTable("battlefieldTint")
  self.createButton({
    click_function = "toggleRangeRuler",
    function_owner = self,
    label = "R",
    tooltip = "Spawn Range Ruler",
    position = {-0.2, 0.1, 1.15},
    rotation = isqButtonRotation(0),
    width = 230,
    height = 180,
    font_size = 100,
    color= {btnTint["r"], btnTint["g"], btnTint["b"], 0.7},
    font_color= {1, 1, 1, 100}
  })
  isqRegisterButton("R", 0)
end

function onDestroy()
  clearRangeRuler()
end

function toggleRangeRuler()
  -- Iron Squadron overlays (see !/IsqOverlays): route this token's R button to
  -- the Projector renderer when they are on, unchanged otherwise.
  if isqOverlaysOn() then
    isqClearRange({figGUID = self.getGUID()})
    if rangeOn then
      rangeOn = false
    else
      isqRangeTrigger({figGUID = self.getGUID()})
      rangeOn = true
    end
    return
  end
  clearRangeRuler()
  rangeOn = not rangeOn
  if rangeOn then
    spawnTokenRangeRuler()
  end
end

function clearRangeRuler()
  if rangeRuler then
    destroyObject(rangeRuler)
    rangeRuler = nil
  end
end

function spawnTokenRangeRuler()
  local rangeRulerTable = getRangeRulerLinks()
  local tokenRulerBundle = rangeRulerTable[rangeKey]
  spawnRangeRuler(self, tokenRulerBundle)
end


function addSilhouetteButton()
    local gameData = getObjectFromGUID(Global.getVar("gameDataGUID"))
    local btnTint = gameData.getTable("battlefieldTint")
    btnData = {
      click_function = "toggleSilhouettes",
      function_owner = self,
      label = "SIL",
      tooltip = "Toggle silhouettes on this unit",
      position = {0.2, 0.1, 1.15},
      rotation = isqButtonRotation(0),
      width = 230,
      height = 180,
      font_size = 100,
      color= {btnTint["r"], btnTint["g"], btnTint["b"], 0.7},
      font_color= {1, 1, 1, 100}
    }
    self.createButton(btnData)
    -- It had no rotation at all, so it read mirrored on the back face too.
    isqRegisterButton("SIL", 0)
  end    

  function toggleSilhouettes()
    if silhouetteState then
      clearSilhouette()
    else
      showSilhouette()
    end
  end
  
  -- Loops through all minis in the unit
  -- Removes all attachments and destroys the first one
  -- The silhouette should be the only attachment, so this should be safe to do
  function clearSilhouette()
    -- May be empty: silhouetteState is saved, the silhouette objects are not.
    local silToDestroy = self.removeAttachments()[1]
    if silToDestroy then
      silToDestroy.destruct()
    end
    silhouetteState = false
  end
  
  -- Loops through all minis in the unit
  -- Spawns a silhouette at the pos and rot of each one
  -- and attaches them using the new attachment feature
  function showSilhouette()
    local pos = self.getPosition()
    local rot = self.getRotation()
    local newSilhouette = spawnSilhouette(self, pos, rot)
    silhouetteState = true
  end
  
  function spawnSilhouette(obj, pos, rot)
    local globals = Global.getTable("templateInfo")
    local scale = 2.0
    local height = 3.0
    local offset = 0.0
    local silhouetteData = "https://steamusercontent-a.akamaihd.net/ugc/5063766435505471684/D97103C9FFB76016DDF9CE66A7622BDB3E810160/"
    if obj ~= nil then
      local objUp = obj.getTransformUp()
      local offsetVector = Vector.new(objUp.x * offset, objUp.y * offset, objUp.z * offset)
      pos = { pos.x + offsetVector.x, pos.y + offsetVector.y, pos.z + offsetVector.z }
    end
    
  
    local silhouette = spawnObject({
      type = "Custom_AssetBundle",
      position = pos,
      rotation = rot,
      scale = {scale,height,scale}
    })
    silhouette.setCustomObject({
        assetbundle = silhouetteData,
        material = 3
    })
    silhouette.setColorTint({1.0,0.56,0.17,0.3})
    if obj ~= nil then
      obj.addAttachment(silhouette)
    end
    return silhouette
  end