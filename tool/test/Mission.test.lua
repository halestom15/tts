-- Tests for mod/src/includes/Mission.ttslua, run with standalone Lua:
--
--   npm run test:lua
--
-- Mission.ttslua has no TTS dependencies, so it can be loaded directly.

dofile("mod/src/includes/Mission.ttslua")

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

-- Deterministic "shuffle": always picks the last index, so decks stay in
-- order and draws come off the end of the list.
local function noShuffle(n)
  return n
end

local function decks()
  return {
    red = {
      objective = {"R-Obj1", "R-Obj2", "R-Obj3"},
      secondary = {"R-Sec1", "R-Sec2", "R-Sec3"},
      advantage = {"R-Adv1", "R-Adv2", "R-Adv3"},
    },
    blue = {
      objective = {"B-Obj1", "B-Obj2", "B-Obj3"},
      secondary = {"B-Sec1", "B-Sec2", "B-Sec3"},
      advantage = {"B-Adv1", "B-Adv2", "B-Adv3"},
    },
  }
end

local function newMission(blueSeat)
  local d = decks()
  return Mission:create({red = d.red, blue = d.blue, blueSeat = blueSeat, random = noShuffle})
end

local function contains(list, value)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end

test("blue revealing the objective makes red reveal the secondary", function()
  local m = newMission("Blue")
  m:revealOpening("objective")
  eq(m.cards.objective.name, "B-Obj3", "objective")
  eq(m.cards.objective.owner, "Blue", "objective owner")
  eq(m.cards.secondary.name, "R-Sec3", "secondary")
  eq(m.cards.advantage.Blue.name, "B-Adv3", "blue advantage")
  eq(m.cards.advantage.Red.name, "R-Adv3", "red advantage")
end)

test("blue revealing the secondary makes red reveal the objective", function()
  local m = newMission("Red")
  m:revealOpening("secondary")
  eq(m.cards.secondary.name, "R-Sec3", "secondary (red seat is blue)")
  eq(m.cards.objective.name, "B-Obj3", "objective")
end)

test("turns alternate starting with blue, four in total", function()
  local m = newMission("Red")
  m:revealOpening("objective")
  eq(m:currentSeat(), "Red", "turn 1")
  m:modify("Red", "pass")
  eq(m:currentSeat(), "Blue", "turn 2")
  m:modify("Blue", "pass")
  eq(m:currentSeat(), "Red", "turn 3")
  m:modify("Red", "pass")
  eq(m:isBuilt(), false, "built after 3")
  m:modify("Blue", "pass")
  eq(m:isBuilt(), true, "built after 4")
  eq(m:currentSeat(), nil, "no seat when built")
end)

test("acting out of turn is rejected", function()
  local m = newMission("Blue")
  m:revealOpening("objective")
  local ok = pcall(function() m:modify("Red", "pass") end)
  eq(ok, false, "red acting on blue's turn")
end)

test("replacing the objective draws from the acting player's deck", function()
  local m = newMission("Blue")
  m:revealOpening("objective") -- objective B-Obj3 (blue)
  m:modify("Blue", "pass")
  m:modify("Red", "replaceObjective")
  eq(m.cards.objective.name, "R-Obj3", "objective now red's")
  eq(m.cards.objective.owner, "Red", "owner")
  eq(m._discards.Blue.objective[1], "B-Obj3", "blue's card discarded to blue")
end)

test("replacing own advantage and forcing the opponent's", function()
  local m = newMission("Blue")
  m:revealOpening("objective")
  m:modify("Blue", "replaceOwnAdvantage")
  eq(m.cards.advantage.Blue.name, "B-Adv2", "blue replaced own")
  m:modify("Red", "forceOpponentAdvantage")
  eq(m.cards.advantage.Blue.name, "B-Adv1", "red forced blue's")
  eq(m.cards.advantage.Red.name, "R-Adv3", "red's own untouched")
end)

test("force opponent advantage can be disabled", function()
  ALLOW_FORCE_OPPONENT_ADVANTAGE = false
  local m = newMission("Blue")
  m:revealOpening("objective")
  eq(contains(m:availableActions("Blue"), "forceOpponentAdvantage"), false, "hidden")
  ALLOW_FORCE_OPPONENT_ADVANTAGE = true
  eq(contains(m:availableActions("Blue"), "forceOpponentAdvantage"), true, "shown")
end)

test("takeBlue moves the blue role but not the turn order", function()
  local m = newMission("Blue")
  m:revealOpening("objective")
  eq(contains(m:availableActions("Blue"), "takeBlue"), false, "blue can't take blue")
  m:modify("Blue", "pass")
  m:modify("Red", "takeBlue")
  eq(m.blueSeat, "Red", "red is now blue")
  eq(m:currentSeat(), "Blue", "turn 3 still blue seat")
  eq(m:result().blueSeat, "Red", "result")
end)

test("an empty deck reshuffles discards including the card just discarded", function()
  local d = decks()
  d.blue.advantage = {"B-Adv1"}
  local m = Mission:create({red = d.red, blue = d.blue, blueSeat = "Blue", random = noShuffle})
  m:revealOpening("objective")
  eq(m.cards.advantage.Blue.name, "B-Adv1", "only advantage")
  m:modify("Blue", "replaceOwnAdvantage")
  eq(m.cards.advantage.Blue.name, "B-Adv1", "redrawn from discards")
  eq(#m._discards.Blue.advantage, 0, "discards emptied")
end)

test("a player with no cards of a kind can't replace the other's card", function()
  local d = decks()
  d.red.objective = {"R-Obj1"}
  local m = Mission:create({red = d.red, blue = d.blue, blueSeat = "Red", random = noShuffle})
  m:revealOpening("objective") -- red reveals R-Obj1, deck now empty
  m:modify("Red", "pass")
  eq(contains(m:availableActions("Blue"), "replaceObjective"), true, "blue can replace")
  m:modify("Blue", "replaceObjective") -- R-Obj1 goes to red's discards
  eq(contains(m:availableActions("Red"), "replaceObjective"), true, "red can redraw from discards")
end)

test("result lists the final cards", function()
  local m = newMission("Blue")
  m:revealOpening("secondary")
  for _ = 1, 4 do
    m:modify(m:currentSeat(), "pass")
  end
  local r = m:result()
  eq(r.objective, "R-Obj3", "objective")
  eq(r.secondary, "B-Sec3", "secondary")
  eq(r.advantage.Blue, "B-Adv3", "blue advantage")
  eq(r.advantage.Red, "R-Adv3", "red advantage")
  eq(r.blueSeat, "Blue", "blue seat")
end)

if failures > 0 then
  print(failures .. " test(s) failed")
  os.exit(1)
end
print("All tests passed")
