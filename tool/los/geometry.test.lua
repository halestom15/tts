-- Geometry tests for mod/src/includes/LineOfSight.ttslua, against brute-force
-- references. Self-contained (meshes are generated), run with:
--
--   npm run test:los
--
-- The engine exposes its pure functions in LOS_TEST when LOS_EXPOSE_FOR_TESTS
-- is set before it loads.

LOS_EXPOSE_FOR_TESTS = true
dofile("mod/src/includes/LineOfSight.ttslua")
local T = LOS_TEST
losSliceEnd = math.huge -- never yield while building meshes

local failures = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  print((ok and "PASS " or "FAIL ") .. name .. (ok and "" or ("\n  " .. tostring(err))))
  if not ok then failures = failures + 1 end
end
local function check(cond, msg)
  if not cond then error(msg, 2) end
end

math.randomseed(1234)
local function rnd(a, b) return a + math.random() * (b - a) end

-- A mesh from OBJ text, built the way TTS meshes are.
local function build(text)
  local entry = {text = text}
  T.meshBuild(entry)
  check(entry.status == "ready", "mesh status " .. tostring(entry.status))
  return entry
end

-- A cluster of random triangles (some written as quads) as OBJ text.
local function randomObj(count)
  local lines, v = {}, 0
  for _ = 1, count do
    local cx, cy, cz = rnd(-3, 3), rnd(0, 2), rnd(-3, 3)
    local corners = math.random() < 0.3 and 4 or 3
    for _ = 1, corners do
      table.insert(lines, string.format("v %.4f %.4f %.4f", cx + rnd(-0.4, 0.4), cy + rnd(-0.4, 0.4), cz + rnd(-0.4, 0.4)))
    end
    v = v + corners
    if corners == 4 then
      table.insert(lines, string.format("f %d %d %d %d", v - 3, v - 2, v - 1, v))
    else
      table.insert(lines, "f -3/1/1 -2/2/2 -1/3/3") -- negative indices with uv/normal parts
    end
  end
  return table.concat(lines, "\n")
end

-- A random oriented box frame, like losMakeObb builds for a placed piece.
local function randomObb()
  local ry, sc = rnd(0, 2 * math.pi), rnd(0.6, 1.8)
  return {
    pos = {x = rnd(-2, 2), y = 0, z = rnd(-2, 2)},
    cosy = math.cos(ry), siny = math.sin(ry), cosx = 1, sinx = 0, cosz = 1, sinz = 0,
    scx = sc, scy = sc, scz = sc,
    center = {x = 0, y = 1, z = 0}, half = {x = 4, y = 2, z = 4},
  }
end

-- Moller-Trumbore over every triangle, same clipping as losMeshBlocks.
local function bruteBlocks(entry, lp, lq, t0, t1)
  local ta, tb = math.max(0, t0 - 0.02), math.min(1, t1 + 0.02)
  local ox, oy, oz = lp[4] + (lq[4] - lp[4]) * ta, lp[5] + (lq[5] - lp[5]) * ta, lp[6] + (lq[6] - lp[6]) * ta
  local dx = lp[4] + (lq[4] - lp[4]) * tb - ox
  local dy = lp[5] + (lq[5] - lp[5]) * tb - oy
  local dz = lp[6] + (lq[6] - lp[6]) * tb - oz
  local R = entry.tris
  for i = 1, entry.n do
    local e1x, e1y, e1z, e2x, e2y, e2z = R.e1x[i], R.e1y[i], R.e1z[i], R.e2x[i], R.e2y[i], R.e2z[i]
    local px, py, pz = dy * e2z - dz * e2y, dz * e2x - dx * e2z, dx * e2y - dy * e2x
    local det = e1x * px + e1y * py + e1z * pz
    if math.abs(det) > 1e-9 then
      local inv = 1 / det
      local tx, ty, tz = ox - R.ax[i], oy - R.ay[i], oz - R.az[i]
      local u = (tx * px + ty * py + tz * pz) * inv
      if u >= 0 and u <= 1 then
        local qx, qy, qz = ty * e1z - tz * e1y, tz * e1x - tx * e1z, tx * e1y - ty * e1x
        local v = (dx * qx + dy * qy + dz * qz) * inv
        if v >= 0 and u + v <= 1 then
          local t = (e2x * qx + e2y * qy + e2z * qz) * inv
          if t >= 0 and t <= 1 then return true end
        end
      end
    end
  end
  return false
end

test("OBJ parse: quads fan into two triangles, negative indices resolve", function()
  local e = build("v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nf 1 2 3 4\nf -4 -3 -2")
  check(e.n == 3, "expected 3 triangles, got " .. e.n)
end)

test("OBJ parse: X is mirrored, as TTS loads models", function()
  local e = build("v 2 0 0\nv 3 0 0\nv 3 1 0\nf 1 2 3")
  check(e.tris.ax[1] == -2, "vertex x should be -2, got " .. e.tris.ax[1])
end)

test("BVH line test matches brute force", function()
  local e = build(randomObj(1500))
  local hits, n = 0, 3000
  for _ = 1, n do
    local obb = randomObb()
    local p = {x = rnd(-8, 8), y = rnd(-1, 4), z = rnd(-8, 8)}
    local q = {x = rnd(-8, 8), y = rnd(-1, 4), z = rnd(-8, 8)}
    local lp, lq = T.localPoints(obb, {p})[1], T.localPoints(obb, {q})[1]
    local t0, t1 = rnd(0, 0.3), rnd(0.7, 1)
    local want = bruteBlocks(e, lp, lq, t0, t1)
    check(T.meshBlocks(e, lp, lq, t0, t1) == want, "mismatch on a random line")
    if want then hits = hits + 1 end
  end
  check(hits > n / 10 and hits < n * 9 / 10, "test lines should both hit and miss (" .. hits .. "/" .. n .. ")")
end)

test("mesh distance test matches brute force", function()
  local e = build(randomObj(400))
  local R = e.tris
  for _ = 1, 600 do
    local obb = randomObb()
    local wx, wz, dist = rnd(-9, 9), rnd(-9, 9), rnd(0, 4)
    -- brute force: the point in the piece's (unrotated, world-scale) frame
    -- against every triangle's footprint
    local px, _, pz = T.toObbFrame(obb, wx, obb.pos.y, wz)
    local best = math.huge
    local function seg(ax, az, bx, bz)
      local dx, dz = bx - ax, bz - az
      local l2 = dx * dx + dz * dz
      local t = l2 > 0 and math.max(0, math.min(1, ((px - ax) * dx + (pz - az) * dz) / l2)) or 0
      return math.sqrt((ax + t * dx - px) ^ 2 + (az + t * dz - pz) ^ 2)
    end
    for i = 1, e.n do
      local s = obb.scx
      local ax, az = R.ax[i] * s, R.az[i] * s
      local bx, bz = (R.ax[i] + R.e1x[i]) * s, (R.az[i] + R.e1z[i]) * s
      local cx, cz = (R.ax[i] + R.e2x[i]) * s, (R.az[i] + R.e2z[i]) * s
      local d1 = (px - bx) * (az - bz) - (ax - bx) * (pz - bz)
      local d2 = (px - cx) * (bz - cz) - (bx - cx) * (pz - cz)
      local d3 = (px - ax) * (cz - az) - (cx - ax) * (pz - az)
      local inside = not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
      best = math.min(best, inside and 0 or math.min(seg(ax, az, bx, bz), seg(bx, bz, cx, cz), seg(cx, cz, ax, az)))
    end
    if math.abs(best - dist) > 1e-6 then
      check(T.pieceWithin(obb, e, wx, wz, dist) == (best <= dist), "mismatch at distance " .. dist)
    end
  end
end)

test("vehicle outline (cylinder and stadium) matches dense sampling", function()
  local checked = 0
  for _ = 1, 3000 do
    local ry = rnd(0, 2 * math.pi)
    local v = {x = 0, z = 0, y0 = 1, y1 = rnd(2, 4), r = rnd(0.5, 2.5),
               h = math.random() < 0.3 and 0 or rnd(0, 3), ax = math.sin(ry), az = math.cos(ry)}
    local p = {x = rnd(-8, 8), y = rnd(0, 5), z = rnd(-8, 8)}
    local q = {x = rnd(-8, 8), y = rnd(0, 5), z = rnd(-8, 8)}
    -- How far inside the shape the line gets at its deepest (negative: it
    -- stays outside), sampled along the line.
    local depth = -math.huge
    for i = 0, 2000 do
      local t = i / 2000
      local y = p.y + (q.y - p.y) * t
      local g = T.vehicleGap(v, p.x + (q.x - p.x) * t, p.z + (q.z - p.z) * t)
      depth = math.max(depth, math.min(-g, y - v.y0, v.y1 - y))
    end
    if math.abs(depth) > 0.02 then -- grazing lines are below the sampling resolution
      check(T.segmentHitsVehicle(p, q, v) == (depth > 0), "mismatch on a random line")
      checked = checked + 1
    end
  end
  check(checked > 1000, "too few unambiguous lines checked")
end)

test("vehicle gap: round and oblong bases", function()
  local round = {x = 0, z = 0, r = 1, h = 0, ax = 0, az = 1}
  check(math.abs(T.vehicleGap(round, 3, 0) - 2) < 1e-9, "round base gap")
  local long = {x = 0, z = 0, r = 1, h = 2, ax = 0, az = 1}
  check(math.abs(T.vehicleGap(long, 0, 4) - 1) < 1e-9, "past the end of an oblong base")
  check(math.abs(T.vehicleGap(long, 3, 1) - 2) < 1e-9, "beside an oblong base")
end)

test("cover read from the map's names and descriptions", function()
  local cases = {
    {"City Structure", "- Obstacle Terrain\n- Open Terrain\n- Heavy Cover", "heavy"},
    {"Market Stall", "- Scatter Terrain\n- Light Cover", "light"},
    {"Barricade", "- Heavy Cover (for non-Creature Troopers)", "heavy", "for non-creature troopers"},
    {"Awning [Light Cover]", "Terrain Type: Scatter", "light"},
    {"Wall", "Terrain Type: Obstacle\r\nCover: Heavy", "heavy"},
    {"Sewer Hatch", "Decorative", nil},
  }
  for _, c in ipairs(cases) do
    local cover, note = T.coverOf({getName = function() return c[1] end, getDescription = function() return c[2] end})
    check(cover == c[3] and note == c[4], c[1] .. ": got " .. tostring(cover) .. " / " .. tostring(note))
  end
end)

test("sample points: 81 per silhouette over four levels", function()
  local pts = T.samplePoints({x = 0, y = 0, z = 0}, {r = 0.5, h = 1.7, o = 0}, {x = 10, y = 0, z = 0})
  check(#pts == 81, "expected 81 points, got " .. #pts)
  local level1 = 0
  for _, p in ipairs(pts) do if p.lvl == 1 then level1 = level1 + 1 end end
  check(level1 == 9, "expected a 3x3 first level, got " .. level1)
end)

if failures > 0 then
  print(failures .. " test(s) failed")
  os.exit(1)
end
print("All tests passed")
