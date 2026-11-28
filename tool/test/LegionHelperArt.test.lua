-- Tests for the card names of Legion Helper's art (LegionHelper.ttslua,
-- legionHelperCatalogueArt), run with standalone Lua:
--
--   npm run test:lua
--
-- Legion Helper spells some cards with the mod's old names, files some units
-- under another faction, repeats a title in the name: each card must still
-- be filed under the catalogue's own key, so that its art reaches the card.

-- Fake TTS ---------------------------------------------------------------
Wait = {frames = function(f, _) f() end, time = function(_, _) return 0 end}
broadcastToAll = function() end
require = function() end
Global = {}
getAllObjects = function() return {} end
dofile("mod/src/includes/CardNames.ttslua")
dofile("mod/src/includes/LegionHelper.ttslua")

local failures = 0
local function check(what, ok)
  print((ok and "ok   " or "FAIL ") .. what)
  if not ok then failures = failures + 1 end
end

-- The catalogue writes "PADMÉ" (generated in JavaScript), where Lua's upper()
-- gives "PADMé": the art must be filed under the catalogue's own key.
_G.CardsSchema = {
  units = {REBEL = {["C-3PO GOLDEN GOD"] = {name = "C-3PO", title = "Golden God"},
                    ["PADMÉ AMIDALA SPIRITED SENATOR"] = {name = "Padmé Amidala", title = "Spirited Senator",
                      commands = {{name = "Hello There"}}}},
           REPUBLIC = {["CLONE COMMANDOS DELTA SQUAD"] = {name = "Clone Commandos", title = "Delta Squad"}}},
  upgrades = {["THE DARKSABER (SABINE)"] = {name = "The Darksaber (Sabine)"},
              ["A-180 PISTOL CONFIG"] = {name = "A-180 Pistol Config", flip = {name = "A-180 Rifle Config"}}},
  commands = {},
}
local filed = legionHelperCatalogueArt({
  units = {REBEL = {["C-3P0 GOLDEN GOD"] = {image = "a", shown = "C-3P0: Golden God"},
                    ["PADME AMIDALA SPIRITED SENATOR"] = {image = "b", shown = "Padme Amidala: Spirited Senator"}},
           MERCENARY = {["C-3P0 GOLDEN GOD"] = {image = "h"}},
           REPUBLIC = {["CLONE COMMANDOS DELTA SQUAD •DELTA SQUAD"] = {image = "i"}}},
  upgrades = {["THE DARKSABER"] = {image = "c", name = "The Darksaber"},
              ["A-180 PISTOL CONFIG"] = {image = "d", name = "A-180 Pistol Config", back = "e", backName = "A-180 Rifle Config"},
              ["NO SUCH CARD"] = {image = "f", name = "No Such Card"}},
  commands = {["HELLO THERE!"] = "g"},
})
check("an old unit name is filed under the catalogue's", filed.units.REBEL["C-3PO GOLDEN GOD"] ~= nil
  and filed.units.REBEL["C-3PO GOLDEN GOD"].shown == "C-3PO: Golden God")
check("an accent the builder leaves out", filed.units.REBEL["PADMÉ AMIDALA SPIRITED SENATOR"].image == "b")
check("a title repeated at the end of the name", filed.units.REPUBLIC["CLONE COMMANDOS DELTA SQUAD"].image == "i")
check("an upgrade through an alias", filed.upgrades["THE DARKSABER (SABINE)"].image == "c")
check("a two-sided upgrade keeps its back", filed.upgrades["A-180 PISTOL CONFIG"].back == "e")
check("a card the mod lacks is kept as it is", filed.upgrades["NO SUCH CARD"].image == "f")
check("a command by its letters", filed.commands["HELLO THERE"] == "g")
local moved = legionHelperCatalogueArt({units = {MERCENARY = {["C-3P0 GOLDEN GOD"] = {image = "h"}}},
  upgrades = {}, commands = {}})
check("a unit under another faction takes its art where the catalogue has it",
  moved.units.REBEL and moved.units.REBEL["C-3PO GOLDEN GOD"].image == "h")

if failures > 0 then
  error(failures .. " failure(s)")
end
print("all passed")
