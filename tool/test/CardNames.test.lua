-- Tests for mod/src/includes/CardNames.ttslua, run with standalone Lua:
--
--   npm run test:lua
--
-- The catalogue was renamed to the spelling printed on the cards (November
-- 2026). Lists written with the old names, or by builders that spell a card
-- otherwise, must still find their card; a name too vague must not.

require = function() end
dofile("mod/src/includes/generated/cards.ttslua")
dofile("mod/src/includes/CardNames.ttslua")
local schema = GENERATED_CARDS_SCHEMA

local failures = 0
local function check(what, ok)
  if not ok then
    failures = failures + 1
    print("FAIL: " .. what)
  end
end

local function fullName(entry)
  if entry.title ~= nil then
    return entry.name .. " " .. entry.title
  end
  return entry.name
end

local function commands()
  local cache = {}
  for _, units in pairs(schema.units) do
    for _, unit in pairs(units) do
      for _, command in ipairs(unit.commands or {}) do
        cache[command.name:upper()] = command
      end
    end
  end
  for _, command in pairs(schema.commands) do
    cache[command.name:upper()] = command
  end
  return cache
end
local COMMANDS = commands()

local function find(kind, name)
  if kind == "upgrade" then
    return CardNames.find("upgrade", schema.upgrades, name)
  elseif kind == "command" then
    return CardNames.find("command", COMMANDS, name)
  end
  for _, units in pairs(schema.units) do
    local unit = CardNames.find("unit", units, name)
    if unit ~= nil then
      return unit
    end
  end
  return nil
end

-- Old catalogue name -> printed name (the 83 renamed cards).
local RENAMED = {
  {"unit", "Agent Kallus Hunter Of Spectres", "Agent Kallus Hunter of Spectres"},
  {"unit", "Arc Troopers", "ARC Troopers"},
  {"unit", "Arc Troopers Strike Team", "ARC Troopers Strike Team"},
  {"unit", "C-3P0 Golden God", "C-3PO Golden God"},
  {"unit", "Chewbacca Hero Of Kashyyyk", "Chewbacca Hero of Kashyyyk"},
  {"unit", "Clone Commander Trained For Leadership", "Clone Commander Trained for Leadership"},
  {"unit", "Darth Vader Dark Lord Of The Sith", "Darth Vader Dark Lord of the Sith"},
  {"unit", "Director Orson Krennic Architect Of Terror", "Director Orson Krennic Architect of Terror"},
  {"unit", "Fifth Brother The Kill is Mine", "Fifth Brother The Kill Is Mine"},
  {"unit", "Gar Saxon Militant Commando", "Gar Saxon Militant Commander"},
  {"unit", "LAAT/LE Patrol Transport", "LAAT/le Patrol Transport"},
  {"unit", "Leia Organa Fearless And Inventive", "Leia Organa Fearless and Inventive"},
  {"unit", "Maul A Rival", "Maul a Rival"},
  {"unit", "Padme Amidala Spirited Senator", "Padmé Amidala Spirited Senator"},
  {"unit", "Persuader-Class Tank Droid", "Persuader-class Tank Droid"},
  {"unit", "Persuader-Class Tank Droid Prototype Tank Droid", "Persuader-class Tank Droid Prototype Tank Droid"},
  {"unit", "R2-D2 Hero Of A Thousand Devices", "R2-D2 Hero of a Thousand Devices"},
  {"unit", "Saber-Class Tank", "Saber-class Tank"},
  {"unit", "T-Series Tactical Droid Programmed For Strategy", "T-Series Tactical Droid Programmed for Strategy"},
  {"unit", "Yoda Grand Master Of The Jedi Order", "Yoda Grand Master of the Jedi Order"},
  {"upgrade", "A-300 Rifle Gunner", "A300 Rifle Gunner"},
  {"upgrade", "AX-108 \"Ground Buzzer\"", "Ax-108 \"Ground Buzzer\""},
  {"upgrade", "\"Bunker Buster\" Shells", "Bunker Buster Shells"},
  {"upgrade", "Burst Of Speed", "Burst of Speed"},
  {"upgrade", "DC-15X ARC Trooper Gunner", "DC-15x ARC Trooper Gunner"},
  {"upgrade", "DC-15X ARC Trooper Sniper", "DC-15x ARC Trooper Sniper"},
  {"upgrade", "DLT-19X Sniper", "DLT-19x Sniper"},
  {"upgrade", "Duck And Cover", "Duck and Cover"},
  {"upgrade", "E-5S B1 Battle Droid", "E-5s B1 Battle Droid"},
  {"upgrade", "Go for Broke", "Go For Broke"},
  {"upgrade", "Grogu the Child", "Grogu The Child"},
  {"upgrade", "Grogu the Child (CotW)", "Grogu The Child (CotW)"},
  {"upgrade", "Hound & Grizzer", "Hound and Grizzer"},
  {"upgrade", "I've Altered The Deal", "I've Altered the Deal"},
  {"upgrade", "Into The Fray", "Into the Fray"},
  {"upgrade", "J-19 Bo-Rifle Blaster", "J-19 Bo-rifle Blaster"},
  {"upgrade", "J-19 Bo-Rifle Staff", "J-19 Bo-rifle Staff"},
  {"upgrade", "Lead by Example", "Lead By Example"},
  {"upgrade", "MO/DK Power Harpoon", "Mo/Dk Power Harpoon"},
  {"upgrade", "Not A Story The Jedi Would Tell", "Not a Story the Jedi Would Tell"},
  {"upgrade", "RT-97c Stormtrooper (Wet)", "RT-97C Stormtrooper (Wet)"},
  {"upgrade", "Seize The Initiative", "Seize the Initiative"},
  {"upgrade", "Stolen RT-97c", "Stolen RT-97C"},
  {"upgrade", "T-7 Ion Snowtrooper", "T-7 Ion Rifle Snowtrooper"},
  {"upgrade", "The Darksaber", "The Darksaber (Sabine)"},
  {"command", "Attack Of the Clones", "Attack of the Clones"},
  {"command", "Brains And Brawn", "Brains and Brawn"},
  {"command", "Bring it Down!", "Bring It Down!"},
  {"command", "Change Of Plans", "Change of Plans"},
  {"command", "Deploy The Garrison", "Deploy the Garrison"},
  {"command", "Die at My Hand", "Die At My Hand"},
  {"command", "Double The Fall", "Double the Fall"},
  {"command", "Duel Of The Fates", "Duel of the Fates"},
  {"command", "Fear And Dead Men", "Fear and Dead Men"},
  {"command", "Full Of Surprises", "Full of Surprises"},
  {"command", "Go, There are Too Many...", "Go, There Are Too Many..."},
  {"command", "Have I Ever Let you Down?", "Have I Ever Let You Down?"},
  {"command", "Hello There!", "Hello There"},
  {"command", "I Am A Jedi", "I Am a Jedi"},
  {"command", "I am Fear", "I Am Fear"},
  {"command", "I am no Jedi", "I Am No Jedi"},
  {"command", "I Care Not for your Struggles", "I Care Not for Your Struggles"},
  {"command", "Knowledge And Defense", "Knowledge and Defense"},
  {"command", "Legacy Of Mandalore", "Legacy of Mandalore"},
  {"command", "Marked for Elimination", "Marked For Elimination"},
  {"command", "Master Of Evil", "Master of Evil"},
  {"command", "MROWGH GHRRMROWRIG!", "Mrowgh Ghrrmrowrig!"},
  {"command", "My Ally Is The Force", "My Ally Is the Force"},
  {"command", "Never Tell Me The Odds", "Never Tell me the Odds"},
  {"command", "New Ways To Motivate Them", "New Ways to Motivate Them"},
  {"command", "Our Fate Is In Your Hands", "Our Fate is in Your Hands"},
  {"command", "Return Of The Jedi", "Return of the Jedi"},
  {"command", "See You in Hell", "See You In Hell"},
  {"command", "Somebody Has To Save Our Skins", "Somebody Has to Save Our Skins"},
  {"command", "Son Of Skywalker", "Son of Skywalker"},
  {"command", "Sorry About The Mess", "Sorry About the Mess"},
  {"command", "Squadron, on me", "Squadron, On Me"},
  {"command", "Symbol Of Rebellion", "Symbol of Rebellion"},
  {"command", "This Is Where The Fun Begins", "This Is Where the Fun Begins"},
  {"command", "Trained In Your Jedi Arts", "Trained in Your Jedi Arts"},
  {"command", "Turning The Tide", "Turning the Tide"},
  {"command", "Unexpected, but not Unwelcome", "Unexpected, But Not Unwelcome"},
  {"command", "We Shall Start With Revenge", "We Shall Start with Revenge"},
}
for _, r in ipairs(RENAMED) do
  local entry = find(r[1], r[2])
  check(r[1] .. " \"" .. r[2] .. "\" finds \"" .. r[3] .. "\"", entry ~= nil and fullName(entry) == r[3])
  entry = find(r[1], r[3])
  check(r[1] .. " \"" .. r[3] .. "\" is in the catalogue", entry ~= nil and fullName(entry) == r[3])
end

-- Other builders' spellings.
local OTHERS = {
  {"unit", "Padme Amidala Spirited Senator", "Padmé Amidala Spirited Senator"},
  {"unit", "PADMÉ AMIDALA SPIRITED SENATOR", "Padmé Amidala Spirited Senator"},
  {"unit", "Gar Saxon Militant Commando", "Gar Saxon Militant Commander"},
  {"unit", "Major Marquand", "Major Marquand Tempest Scout 2"},
  {"unit", "Luke Skywalker Hero Of The Rebellion", "Luke Skywalker Hero of the Rebellion"},
  {"unit", "General Grievous Wheel Bike Warlord", "General Grievous Wheel Bike Warlord"},
  {"command", "Into the Breach", "Into the Breach"},
  {"upgrade", "Mertalizer", "Mertalizer Dark Trooper"},
  {"upgrade", "Mertalizer Dark Trooper", "Mertalizer Dark Trooper"},
  {"upgrade", "Missile Pod Rocket Droid", "Anti-Infantry Missile Pod Rocket Droid"},
  {"upgrade", "Anti-Infantry Missile Pod Rocket Droid", "Anti-Infantry Missile Pod Rocket Droid"},
  {"upgrade", "The Mando's Jetpack", "Din's Jetpack"},
  {"upgrade", "Echo The Bad Batch", "Echo, Clone Force 99"},
  {"upgrade", "Paz Viszla", "Paz Vizsla"},
  {"upgrade", "Clone Trooper Marksman", "Clone Marksman"},
  {"upgrade", "Tools of the Trade, Whipcord Launcher", "Whipcord Launcher"},
  {"upgrade", "Tools of the Trade, Jetpack Rockets", "Jetpack Rockets"},
  {"upgrade", "Grogu", "Grogu The Child"},
  {"upgrade", "Grogu The Child (CotW)", "Grogu The Child (CotW)"},
  {"command", "Agressive Negotiations", "Aggressive Negotiations"},
  {"command", "Out Of The Shadow", "Out of the Shadows"},
  {"upgrade", "C-3PO Human-Cyborg Relations", "C-3PO Human Cyborg Relations"},
  {"upgrade", "A280", "A280, Pistol Config"},
  {"upgrade", "E-11D", "E-11D Focused Fire Config"},
  {"upgrade", "DC-17m ICWS", "DC-17m ICWS Config"},
  {"upgrade", "A-180", "A-180 Pistol Config"},
  {"upgrade", "Hound & Grizzer", "Hound and Grizzer"},
  {"upgrade", "\"Bunker Buster\" Shells", "Bunker Buster Shells"},
  {"upgrade", "The Darksaber", "The Darksaber (Sabine)"},
  {"upgrade", "The Darksaber (Gideon)", "The Darksaber (Gideon)"},
  {"upgrade", "J-19 Bo-rifle", "J-19 Bo-rifle Blaster"},
  {"upgrade", "C-3PO Made to Suffer", "C-3PO"},
  {"command", "Hello There!", "Hello There"},
}
for _, r in ipairs(OTHERS) do
  local entry = find(r[1], r[2])
  check(r[1] .. " \"" .. r[2] .. "\" finds \"" .. r[3] .. "\"", entry ~= nil and fullName(entry) == r[3])
end

-- A unit of a list whose faction is empty (Tabletop Admiral's battle forces,
-- read as "mercenary") or unknown (DTT's "fringe") is still found.
local function unitOf(faction, name)
  local unit, key = CardNames.findUnit(schema.units, faction, name)
  return unit and fullName(unit), key
end
check("battle force, empty faction: Clone Trooper Infantry", unitOf("", "Clone Trooper Infantry") == "Clone Trooper Infantry")
check("battle force, empty faction: Darth Vader", unitOf("", "Darth Vader Dark Lord Of The Sith") == "Darth Vader Dark Lord of the Sith")
check("mercenary read for an empty faction: Clone Trooper Infantry", unitOf("mercenary", "Clone Trooper Infantry") == "Clone Trooper Infantry")
check("DTT's fringe: Mandalorian Warriors", select(2, unitOf("fringe", "Mandalorian Warriors")) == "MERCENARY")
check("old lists' imperial: Stormtroopers", select(2, unitOf("imperial", "Stormtroopers")) == "EMPIRE")
check("the list's faction comes first", select(2, unitOf("empire", "Bossk Trandoshan Terror")) == "EMPIRE")
check("then the mercenaries", select(2, unitOf("", "Bossk Trandoshan Terror")) == "MERCENARY")
check("no faction at all", unitOf(nil, "AT-RT") == "AT-RT")
check("a unit no faction has", unitOf("republic", "Clone Commandos (DS) Delta Squad") == nil)

-- Too vague: several cards could be meant, the list gets a dud.
check("\"Heavy Blaster Pistol\" alone finds nothing", find("upgrade", "Heavy Blaster Pistol") == nil)
check("\"Combat Armor\" alone finds nothing", find("upgrade", "Combat Armor") == nil)

-- Every alias leads to a card of the catalogue.
for kind, list in pairs(CardNames.ALIASES) do
  for from, to in pairs(list) do
    check(kind .. " alias \"" .. from .. "\" leads to \"" .. to .. "\"", find(kind, to) ~= nil)
  end
end

-- No two cards of a kind share a key: step 3 would pick one at random.
local function noCollision(kind, entries)
  local seen = {}
  for _, entry in pairs(entries) do
    local key = CardNames.key(fullName(entry))
    check(kind .. " key \"" .. key .. "\" names one card only (" .. fullName(entry) .. ")",
      seen[key] == nil or seen[key] == fullName(entry))
    seen[key] = fullName(entry)
  end
end
for faction, units in pairs(schema.units) do
  noCollision("unit of " .. faction, units)
end
noCollision("upgrade", schema.upgrades)
noCollision("command", COMMANDS)

-- Every unit named by an upgrade's restrictions exists (compared ignoring
-- case, as Deck:_isUpgradeValidFor does). KNOWN: a unit the game no longer has.
local KNOWN = {
  ["Electrostaff Guard|IMPERIAL ROYAL GUARDS"] = true,
}
local unitNames = {}
for _, units in pairs(schema.units) do
  for _, unit in pairs(units) do
    unitNames[unit.name:upper()] = true
  end
end
for _, upgrade in pairs(schema.upgrades) do
  local include = upgrade.restrictions and upgrade.restrictions.include
  for _, name in ipairs(include and include.unit or {}) do
    check(upgrade.name .. " restricted to an existing unit (" .. name .. ")",
      unitNames[name:upper()] == true or KNOWN[upgrade.name .. "|" .. name:upper()] == true)
  end
end

-- Errata Nov. 2026: Grogu is "Counterpart: Din Djarin, IG-11".
local ig11 = CardNames.findUnit(schema.units, "", "IG-11 Nurse and Protect")
check("IG-11 has a Counterpart slot", ig11 ~= nil and ig11.upgrades.Counterpart == 1)
for _, name in ipairs({"GROGU THE CHILD", "GROGU THE CHILD (COTW)"}) do
  local allowed = {}
  for _, unit in ipairs(schema.upgrades[name].restrictions.include.unit) do
    allowed[unit] = true
  end
  check(name .. " goes to IG-11 and both Din Djarin",
    allowed["IG-11"] and allowed["Din Djarin"] and allowed["Din Djarin (CotW)"])
end

if failures > 0 then
  error(failures .. " failure(s)")
end
print("all passed")
