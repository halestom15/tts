-- Tests for the list import of mod/src/includes/data/ListBuilderNew.ttslua,
-- run with standalone Lua:
--
--   npm run test:lua
--
-- A LegionHQ list copied from Longshanks has "||" where its line breaks were
-- (seen on 711 lists harvested in Nov. 2026). The import mends it.

-- ListBuilderNew.ttslua runs TTS code at load: take the function alone.
local src = io.open("mod/src/includes/data/ListBuilderNew.ttslua"):read("*a")
local a = src:find("function repairLongshanksList%(text%)")
assert(a, "repairLongshanksList not found")
local b = src:find("\nend\n", a, true)
-- loadstring: the CI's Lua 5.1, where load takes no string
local compile = rawget(_G, "loadstring") or load
compile(src:sub(a, b + 4))()

local failures = 0
local function check(what, ok)
  if not ok then
    failures = failures + 1
    print("FAIL: " .. what)
  end
end

local broken = '{ ||     "author": "Legion HQ", ||     "armyFaction": "rebel", ||'
  .. '     "units": [ ||         { "name": "B2-AC || M Battle Droid" } ||     ] || }'
local mended = repairLongshanksList(broken)
check("no \"||\" left", not mended:find("||", 1, true))
check("the structure is kept", mended:match('^{%s+"author": "Legion HQ",%s+"armyFaction": "rebel",'
  .. '%s+"units": %[%s+{ "name": "B2%-AC%s+M Battle Droid" }%s+%]%s+}$') ~= nil)
check("a list without \"||\" is left alone",
  repairLongshanksList('{"author":"Tabletop Admiral"}') == '{"author":"Tabletop Admiral"}')

if failures > 0 then
  error(failures .. " failure(s)")
end
print("all passed")
