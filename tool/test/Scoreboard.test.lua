-- Tests for the click rules in mod/src/includes/Scoreboard.ttslua, run with
-- standalone Lua:
--
--   npm run test:lua
--
-- Loading the file only defines functions; Scoreboard.clicked and
-- Scoreboard.vpSpot make no TTS calls.

dofile("mod/src/includes/Scoreboard.ttslua")

local failures = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  " .. tostring(err))
  end
end

local function eq(actual, expected, label)
  if actual ~= expected then
    error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local function marker(role, vp)
  return {kind = "marker", role = role, vp = vp, supply = 3}
end

test("left-click scores a point, from 0 to space 1", function()
  eq(Scoreboard.clicked(marker("Red", 0), false, "Blue").vp, 1)
end)

test("right-click takes a point back", function()
  eq(Scoreboard.clicked(marker("Red", 5), true, "Red").vp, 4)
end)

test("VP doesn't go below 0", function()
  eq(Scoreboard.clicked(marker("Blue", 0), true, "Blue").vp, 0)
end)

test("past 12 the marker goes round once more, up to 24", function()
  eq(Scoreboard.clicked(marker("Blue", 12), false, "Blue").vp, 13, "13")
  eq(Scoreboard.clicked(marker("Blue", 24), false, "Blue").vp, 24, "not above 24")
  eq(Scoreboard.vpSpot("Blue", 13)[1], Scoreboard.vpSpot("Blue", 1)[1], "13 on space 1")
  eq(Scoreboard.vpSpot("Red", 24)[1], Scoreboard.vpSpot("Red", 12)[1], "24 on space 12")
  eq(Scoreboard.lapped(0), false, "lapped at 0")
  eq(Scoreboard.lapped(12), false, "lapped at 12")
  eq(Scoreboard.lapped(13), true, "lapped at 13")
end)

test("a marker in play keeps its player and look whoever clicks it", function()
  local new, picks = Scoreboard.clicked(marker("Blue", 3), false, "Red")
  eq(new.role, "Blue", "role")
  eq(new.supply, 3, "supply")
  eq(picks, nil, "picks")
end)

test("a supply token is picked by the clicker and stays in the supply", function()
  local supply = {kind = "supply", supply = 5}
  local new, picks = Scoreboard.clicked(supply, false, "Red")
  eq(new, supply, "unchanged")
  eq(picks, "Red", "picks")
end)

test("a supply token ignores a player without a seat", function()
  local _, picks = Scoreboard.clicked({kind = "supply", supply = 2}, false, nil)
  eq(picks, nil, "picks")
end)

test("the round marker runs from 1 to 5", function()
  eq(Scoreboard.clicked({kind = "round", round = 1}, false).round, 2, "next")
  eq(Scoreboard.clicked({kind = "round", round = 1}, true).round, 1, "not below 1")
  eq(Scoreboard.clicked({kind = "round", round = 5}, false).round, 5, "not above 5")
  eq(Scoreboard.clicked({kind = "round", round = 4}, true).round, 3, "previous")
end)

test("VP spots: 0 is left of the track, 1..12 step across it", function()
  local zero, one, twelve = Scoreboard.vpSpot("Blue", 0), Scoreboard.vpSpot("Blue", 1), Scoreboard.vpSpot("Red", 12)
  assert(zero[1] < one[1], "0 left of 1")
  eq(string.format("%.4f", twelve[1]), string.format("%.4f", 0.187 + 11 * 0.0583), "space 12")
  assert(Scoreboard.vpSpot("Red", 3)[2] > Scoreboard.vpSpot("Blue", 3)[2], "red row below blue")
end)

local function near(actual, expected, label)
  local diff = (actual - expected + 180) % 360 - 180
  if math.abs(diff) > 0.01 then
    error((label or "angle") .. ": expected " .. expected .. ", got " .. actual, 2)
  end
end

-- TTS is Lua 5.2 (MoonSharp): math.atan takes one argument, and atan2 is
-- separate. Reload the file under that shape, as TTS would see it.
test("card rotations under TTS's Lua 5.2 maths", function()
  local atan = math.atan
  math.atan2 = function(y, x) return atan(y, x) end
  math.atan = function(y) return atan(y) end
  local ok, err = pcall(function()
    dofile("mod/src/includes/Scoreboard.ttslua")
    local board = {x = 49.34, y = 270.01, z = 0}
    local flat = Scoreboard.spunRotation(board, 0)
    near(flat.x, 49.34, "upright x")
    near(flat.y, 270.01, "upright y")
    near(flat.z, 0, "upright z")
    local sideways = Scoreboard.spunRotation(board, 90)
    near(sideways.x, 0, "sideways x")
    near(sideways.z, 49.34, "sideways z")
  end)
  math.atan, math.atan2 = atan, nil
  assert(ok, err)
end)

local function close(actual, expected, label)
  if math.abs(actual - expected) > 0.0001 then
    error((label or "value") .. ": expected " .. expected .. ", got " .. actual, 2)
  end
end

-- Every mission's map card in official.json falls into one of these two
-- real pixel shapes: Cauldron (488x345, ratio 1.414) for the four
-- wider-than-tall maps (confirmed live: no turn), and Bunker Assault
-- (726x1039, ratio 0.699) for the other nine, including all three Recon
-- maps (confirmed live: a clockwise quarter turn).
test("map card: wider-than-tall image needs no turn", function()
  local targetWidth = 2.4
  local scale, spin = Scoreboard.mapCardFit(488, 345, targetWidth)
  eq(spin, 0, "spin")
  close(scale * 488, targetWidth, "width scales to fill the slot's reserved span")
  close((scale * 345) / targetWidth, 345 / 488, "height keeps the image's own aspect ratio")
end)

test("map card: taller-than-wide image turns a clockwise quarter", function()
  local targetWidth = 2.4
  local scale, spin = Scoreboard.mapCardFit(726, 1039, targetWidth)
  eq(spin, 90, "spin")
  close(scale * 1039, targetWidth, "height scales to fill the slot's reserved span, once turned")
  close((scale * 726) / targetWidth, 726 / 1039, "width keeps the image's own aspect ratio")
end)

if failures > 0 then
  print(failures .. " test(s) failed")
  os.exit(1)
end
print("All tests passed")
