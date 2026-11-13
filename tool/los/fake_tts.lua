-- A minimal fake of the TTS API, enough to run includes/LineOfSight.ttslua
-- outside the game (see run_scene.lua). Objects are plain tables built from
-- a scene description; meshes are served from local files; frames are
-- simulated by resuming the engine's coroutines.

local fake = {objects = {}, byGuid = {}, timers = {}, routines = {}, downloads = {}, ui = {}, calls = {},
  frames = 0, luaTime = 0}

local function readFile(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("a")
  f:close()
  return s
end
fake.readFile = readFile

local function vec(x, y, z) return {x = x, y = y, z = z} end

-- spec = {guid, name, type ("Custom_Model" | "Custom_Assetbundle"),
--         pos, rot, scale, description, vars, mesh (url), bounds}
-- bounds = {center = {x,y,z}, size = {x,y,z}} at zero rotation (world scale,
-- relative to pos), used for both visual and collider bounds.
function fake.addObject(spec)
  local o = {name = spec.type or "Custom_Model", type = "Generic"}
  local vars = spec.vars or {}
  local function rotated(c)
    -- local offset -> world offset, yaw only (enough for terrain and minis)
    local ry = math.rad(spec.rot.y)
    local cs, sn = math.cos(ry), math.sin(ry)
    return c.x * cs + c.z * sn, -c.x * sn + c.z * cs
  end
  function o.getGUID() return spec.guid end
  function o.getName() return spec.name or "" end
  function o.getDescription() return spec.description or "" end
  function o.getPosition() return vec(spec.pos.x, spec.pos.y, spec.pos.z) end
  function o.getRotation() return vec(spec.rot.x, spec.rot.y, spec.rot.z) end
  function o.getScale() return vec(spec.scale.x, spec.scale.y, spec.scale.z) end
  function o.getVar(k) return vars[k] end
  function o.isDestroyed() return false end
  function o.call(fn, params) table.insert(fake.calls, {guid = spec.guid, fn = fn, params = params}) end
  function o.getCustomObject() return {mesh = spec.mesh} end
  local function normalized()
    local b = spec.bounds or {center = vec(0, 0.5, 0), size = vec(1, 1, 1)}
    return {center = vec(spec.pos.x + b.center.x, spec.pos.y + b.center.y, spec.pos.z + b.center.z), size = b.size}
  end
  local function world()
    local b = spec.bounds or {center = vec(0, 0.5, 0), size = vec(1, 1, 1)}
    local dx, dz = rotated(b.center)
    return {center = vec(spec.pos.x + dx, spec.pos.y + b.center.y, spec.pos.z + dz), size = b.size}
  end
  o.getVisualBoundsNormalized = normalized
  o.getBoundsNormalized = normalized
  o.getBounds = world
  table.insert(fake.objects, o)
  fake.byGuid[spec.guid] = o
  return o
end

-- Installs the fake globals. meshFiles maps mesh URL -> local OBJ path.
function fake.install(meshFiles, cardsSchema)
  getAllObjects = function() return fake.objects end
  getObjectFromGUID = function(g) return fake.byGuid[g] end
  CardsSchema = cardsSchema
  Global = {
    setVectorLines = function(lines) fake.lines = lines end,
    getVectorLines = function() return fake.lines end,
  }
  UI = {
    setAttribute = function(id, k, v) fake.ui[id .. "." .. k] = v end,
    setValue = function(id, v) fake.ui[id] = v end,
    getValue = function(id) return fake.ui[id] end,
  }
  Wait = {time = function(fn) table.insert(fake.timers, fn) end}
  WebRequest = {get = function(url, cb)
    table.insert(fake.downloads, {url = url, cb = cb, frames = 3})
  end}
  Physics = {cast = function() return nil end} -- no colliders offline: boxes decide
  startLuaCoroutine = function(_, name)
    table.insert(fake.routines, coroutine.create(_G[name]))
  end
  fake.meshFiles = meshFiles
end

-- One simulated frame: deliver due downloads, resume every coroutine.
function fake.frame()
  fake.frames = fake.frames + 1
  for i = #fake.downloads, 1, -1 do
    local d = fake.downloads[i]
    d.frames = d.frames - 1
    if d.frames <= 0 then
      table.remove(fake.downloads, i)
      local path = fake.meshFiles[d.url]
      if path then
        d.cb({is_error = false, text = readFile(path)})
      else
        d.cb({is_error = true})
      end
    end
  end
  for i = #fake.routines, 1, -1 do
    local t = os.clock()
    local ok, err = coroutine.resume(fake.routines[i])
    fake.luaTime = fake.luaTime + os.clock() - t
    if not ok then error("coroutine error: " .. tostring(err)) end
    if coroutine.status(fake.routines[i]) == "dead" then table.remove(fake.routines, i) end
  end
end

-- Runs frames until every coroutine has finished (or the cap is reached).
function fake.settle(maxFrames)
  local start = fake.frames
  while (#fake.routines > 0 or #fake.downloads > 0) and fake.frames - start < (maxFrames or 100000) do
    fake.frame()
  end
  return fake.frames - start
end

return fake
