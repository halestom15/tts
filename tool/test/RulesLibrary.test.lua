-- Tests for mod/src/includes/data/RulesLibrary.ttslua, run with standalone Lua:
--
--   npm run test:lua
--
-- A lectern loads its document under a url dated by Drive's Last-Modified, so
-- that Tabletop Simulator downloads a new edition instead of serving its cache.
-- These tests hold the dating to its promises: one callback, a dated url when
-- Drive answers, the bare url otherwise, and every lectern url, dated or not,
-- traced back to its library entry.

-- Fake TTS ---------------------------------------------------------------

local timers, nextTimer = {}, 0
Wait = {
  time = function(f, _)
    nextTimer = nextTimer + 1
    timers[nextTimer] = f
    return nextTimer
  end,
  stop = function(id) timers[id] = nil end,
}
local function fireTimers()
  for id, f in pairs(timers) do
    timers[id] = nil
    f()
  end
end

local pendingAnswer
WebRequest = {
  custom = function(_, method, _, _, _, callback)
    assert(method == 'HEAD', 'the date must be asked without downloading the file')
    pendingAnswer = callback
  end,
}
local function answer(req)
  local callback = pendingAnswer
  pendingAnswer = nil
  callback(req)
end
local function driveReply(code, modified)
  return {
    is_error = code ~= 200,
    response_code = code,
    getResponseHeader = function(name)
      if name == 'Last-Modified' then return modified end
    end,
  }
end

dofile("mod/src/includes/data/RulesLibrary.ttslua")

-- Tests ------------------------------------------------------------------

local failures = 0
local function check(name, ok)
  if ok then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name)
  end
end

local url = RULES_LIBRARY[1].en
local function collect()
  local calls = {}
  rulesDatedUrl(url, function(result) calls[#calls + 1] = result end)
  return calls
end

do
  local calls = collect()
  answer(driveReply(200, 'Wed, 18 Nov 2026 11:04:54 GMT'))
  fireTimers()
  check("Drive answers: dated url, once",
    #calls == 1 and calls[1] == url .. '&v=Wed18Nov2026110454GMT')
end

do
  local calls = collect()
  answer(driveReply(404, nil))
  fireTimers()
  check("Drive refuses: bare url, once", #calls == 1 and calls[1] == url)
end

do
  local calls = collect()
  answer(driveReply(200, nil))
  check("no Last-Modified: bare url", #calls == 1 and calls[1] == url)
end

do
  local calls = collect()
  fireTimers()
  answer(driveReply(200, 'Wed, 18 Nov 2026 11:04:54 GMT'))
  check("Drive too slow: bare url, and its late answer is ignored",
    #calls == 1 and calls[1] == url)
end

do
  local dated = url .. '&v=Wed18Nov2026110454GMT'
  check("a dated url finds its entry", rulesChoiceForUrl(dated) == RULES_LIBRARY_BY_URL[url])
  check("a bare url finds its entry", rulesChoiceForUrl(url) == RULES_LIBRARY_BY_URL[url])
  check("an unknown url finds nothing", rulesChoiceForUrl('https://example.org/x.pdf') == nil)
  check("no url finds nothing", rulesChoiceForUrl(nil) == nil)
end

do
  local count = 0
  for _, doc in ipairs(RULES_LIBRARY) do
    if doc.en then count = count + 1 end
    if doc.fr then count = count + 1 end
  end
  check("every document in every language is a choice", #RULES_LIBRARY_CHOICES == count)
end

if failures > 0 then
  print(failures .. " failure(s)")
  os.exit(1)
end
print("all passed")
