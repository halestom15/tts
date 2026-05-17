#!/usr/bin/env python3
"""
Patch a TTS save JSON (SWL mod beta) to add Mac Cohesion fallback.

Two-part patch:
1. Append manager + event handlers to the Global LuaScript.
2. Replace the inline Cohesion block in Unit_Leader (99f1c8) and Order_Token
   (a57c41) with delegated stubs that call the Global manager via Global.call.

The native hotkey "Show Cohesion On Hovered Model" and the Order Token
"COHESION" button automatically use the patched code afterwards  -  they
spawn vector-lines rings instead of legacy Custom_AssetBundle Projectors.

Usage:
    python3 patch_save_for_mac.py <input.json> <output.json>
"""
import json
import re
import socket
import sys
from pathlib import Path

# ------------------------------------------------------------
# 1) Code appended to Global LuaScript (manager + event handlers)
# ------------------------------------------------------------
GLOBAL_PATCH_LUA = r"""

-- ============================================
-- MAC COHESION FALLBACK (auto-injected for TTS U6 magenta bug)
-- Manager Global + event handlers + vector-lines rendering.
-- Called by Unit_Leader / Order_Token via Global.call from their patched
-- Cohesion functions.
-- ============================================

-- Capture the ORIGINAL Global functions loaded by !/RangeRulers and
-- !/Cohesion BEFORE we overwrite them below. We also capture the inner
-- spawn/clear pair because the toggle wrapper resolves them by NAME at
-- call time  -  without aliasing those too, the original toggle would route
-- back into our Mac versions, defeating Windows mode entirely.
spawnRangeRulerOriginalGlobal     = spawnRangeRuler
clearRangeRulersOriginalGlobal    = clearRangeRulers
spawnCohesionRulerOriginalGlobal  = spawnCohesionRuler
clearCohesionRulerOriginalGlobal  = clearCohesionRuler

activeOverlays = activeOverlays or {}
hiddenWhilePickedUp = hiddenWhilePickedUp or {}

local ASSETS_BASE = "https://raw.githubusercontent.com/ironsquadronfr-hub/tts/mac-projector-fallback/mod/data/mac-fallback-assets/"
local COHESION_HALO_URL = ASSETS_BASE .. "cohesion_halo.png"
local MAX_MOVE_CYAN_URL = ASSETS_BASE .. "max_move_cyan.png"
local DEPLOYMENT_RED_URL = ASSETS_BASE .. "deployment_red.png"
local DEPLOYMENT_BLUE_URL = ASSETS_BASE .. "deployment_blue.png"
local RANGE_DECAL_URLS = {
    smokeToken    = ASSETS_BASE .. "range_smokeToken.png",
    token         = ASSETS_BASE .. "range_token.png",
    tokenRangeTwo = ASSETS_BASE .. "range_tokenRangeTwo.png",
    poi           = ASSETS_BASE .. "range_poi.png",
    bombCart      = ASSETS_BASE .. "range_bombCart.png",
    -- Fig leaders: per-base-size PNGs (bands pre-offset by the base radius so
    -- the decal bands line up with the vector-line rings).
    fig_leader = {
        small  = ASSETS_BASE .. "range_fig_leader_small.png",
        medium = ASSETS_BASE .. "range_fig_leader_medium.png",
        large  = ASSETS_BASE .. "range_fig_leader_large.png",
        huge   = ASSETS_BASE .. "range_fig_leader_huge.png",
        laat   = ASSETS_BASE .. "range_fig_leader_laat.png",
        epic   = ASSETS_BASE .. "range_fig_leader_epic.png",
        long   = ASSETS_BASE .. "range_fig_leader_long_stadium.png",
        snail  = ASSETS_BASE .. "range_fig_leader_snail_stadium.png",
    },
}
local RANGE_MAX_RADIUS = {
    fig_leader    = 30,  -- R5 max
    -- SWL: Range 1 = 6", Range 2 = 12", Range 0.5 = 3".
    smokeToken    = 6,
    token         = 6,
    tokenRangeTwo = 12,
    poi           = 3,
    bombCart      = 12,
}

-- Range band colors (RGBA) extracted from BB_RangeProjector material defaults
-- + demi-portee blanche pour SWL Range 0.5 (3 inches)
local RANGE_COLORS = {
    half  = {1.0,   1.0,   1.0,   0.6},   -- 0.5 = 3" white
    one   = {1.0,   0.764, 0.0,   0.7},   -- R1 yellow
    two   = {1.0,   0.459, 0.0,   0.7},   -- R2 orange
    three = {1.0,   0.079, 0.0,   0.7},   -- R3 red
    four  = {0.764, 0.0,   0.259, 0.7},   -- R4 magenta
    five  = {0.528, 0.0,   0.443, 0.7},   -- R5 violet
}

-- Per-rangeKey configurations: list of {radius_inches, color_name}
local RANGE_CONFIGS = {
    -- Fig leaders: half + 4 bands at SWL standard ranges 3/6/12/18/24"
    small  = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    medium = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    large  = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    huge   = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    laat   = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    epic   = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    long   = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    snail  = {{r=3,c="half"},{r=6,c="one"},{r=12,c="two"},{r=18,c="three"},{r=24,c="four"},{r=30,c="five"}},
    -- Token rangeKeys (1 to 2 bands depending on use). SWL ranges in inches:
    -- Range 1 = 6", Range 2 = 12", Range 0.5 (poi) = 3".
    smokeToken    = {{r=6,c="one"}},
    token         = {{r=6,c="one"}},
    tokenRangeTwo = {{r=6,c="one"},{r=12,c="two"}},
    poi           = {{r=3,c="one"}},
    bombCart      = {{r=6,c="one"},{r=12,c="two"}},
}

-- Base footprint dimensions in mm. width <= length; equal means round.
-- Used to drive round vs stadium overlay shape.
local BASE_DIMENSIONS = {
    small  = {width =  27, length =  27},
    medium = {width =  50, length =  50},
    large  = {width =  70, length =  70},
    huge   = {width = 100, length = 100},
    laat   = {width = 120, length = 120},
    epic   = {width = 150, length = 150},
    long   = {width = 100, length = 175},  -- oblong
    snail  = {width = 100, length = 200},  -- oblong
}

-- Base radius (inches) for round overlays. For oblong bases we use a
-- stadium shape instead (see macBuildStadium), so the radius here is the
-- half-width that drives the cap arcs.
local FIG_BASE_RADIUS_IN = {}
for k, d in pairs(BASE_DIMENSIONS) do
    FIG_BASE_RADIUS_IN[k] = (d.width / 2) / 25.4
end

local function macIsOblong(baseSize)
    local d = BASE_DIMENSIONS[baseSize]
    return d ~= nil and d.length > d.width
end

-- Returns the stadium half-dimensions (inches) and yaw for an oblong base,
-- or nil if the fig's base is round. Callers should branch on the return.
local function macOblongDims(fig, baseSize)
    if not macIsOblong(baseSize) then return nil end
    local d = BASE_DIMENSIONS[baseSize]
    return {
        halfLen = (d.length / 2) / 25.4,
        halfWid = (d.width  / 2) / 25.4,
        rotY    = fig.getRotation().y,
    }
end

-- Resolve baseSize for a fig. The mod stores it as a script-local Var on the
-- fig itself (set at spawn from the unit's container). unitData.baseSize is
-- only populated on the Unit Leader, not on minis/vehicles  -  so getVar is
-- the canonical read, with unitData as fallback for safety.
local function macGetBaseSize(fig)
    if not fig then return nil end
    local ok, bs = pcall(function() return fig.getVar("baseSize") end)
    if ok and bs then return bs end
    local data = fig.getTable("unitData")
    if data and data.baseSize then return data.baseSize end
    return nil
end

local function macFigBaseRadius(fig)
    if not fig then return 0.5315 end
    local bs = macGetBaseSize(fig)
    return (bs and FIG_BASE_RADIUS_IN[bs]) or 0.5315
end

-- Token base radii (inches)  -  measured from token edge for range bands
local TOKEN_BASE_RADIUS = {
    smokeToken    = 18.8 / 2 / 25.4,   -- 0.370"
    token         = 25.1 / 2 / 25.4,   -- 0.494"
    tokenRangeTwo = 25.1 / 2 / 25.4,   -- 0.494"
    poi           = 50.8 / 2 / 25.4,   -- 1.000"
    bombCart      = 50.0 / 2 / 25.4,   -- 0.984"
}

-- Hotkey-driven range on tokens renders fig-leader-style bands using the
-- closest equivalent base size (so the visual matches what a unit of that
-- footprint would see). Token R button keeps the single ring (token-spec).
local TOKEN_TO_BASESIZE = {
    smokeToken    = "small",
    token         = "small",
    tokenRangeTwo = "small",
    poi           = "medium",
    bombCart      = "medium",
}

-- Maximum Move radii (inches), indexed by baseSize then speed 1..3
-- Source: ProjectorRadius from BB_MovementProjector materials (single variants)
local MAX_MOVE_RADIUS = {
    small  = { 4.547244,  6.515748,  8.484252},   -- 27mm
    medium = { 5.669292,  7.637795,  9.606299},   -- 50mm
    large  = { 6.850394,  8.818897, 10.787401},   -- 70mm
    huge   = { 8.622047, 10.590551, 12.559055},   -- 100mm
    laat   = { 9.803149, 11.771653, 13.740157},   -- 120mm
    epic   = {11.574803, 13.543307, 15.511811},   -- 150mm
    long   = {13.051181, 15.019685, 16.988190},   -- oblong
    snail  = {14.527559, 16.496063, 18.464567},   -- snail
}

-- Deployment cell dimensions (width X, depth Z, inches).
-- All cells live on a 6"x6" grid; sub-cells are halves/quarters of that cell.
local DEPLOYMENT_CELL_SIZES = {
    r   = {6, 6}, b   = {6, 6},   -- full cell
    rl  = {6, 6}, bl  = {6, 6},   -- large variant (also full cell)
    rh  = {6, 3}, bh  = {6, 3},   -- horizontal half (3" deep)
    rs  = {3, 6}, bs  = {3, 6},   -- vertical half (3" wide), x-offset +1.5
    rss = {3, 6}, bss = {3, 6},   -- vertical half (3" wide), x-offset -1.5
    rc  = {3, 3}, bc  = {3, 3},   -- corner quarter
    rcc = {3, 3}, bcc = {3, 3},   -- opposite corner quarter
}

local function macRayGroundY(x, z, offset)
    local hits = Physics.cast({
        origin       = {x, 30, z},
        direction    = {0, -1, 0},
        type         = 1,
        max_distance = 50,
    })
    for _, h in ipairs(hits) do
        return h.point.y + (offset or 0.05)
    end
    return offset or 0.05
end

local function macBuildRect(cx, cz, hw, hd, color, thickness)
    local segPerSide = 8
    local pts = {}
    local corners = {
        {cx - hw, cz + hd}, {cx + hw, cz + hd},
        {cx + hw, cz - hd}, {cx - hw, cz - hd},
    }
    for i = 1, 4 do
        local a = corners[i]
        local b = corners[i % 4 + 1]
        for s = 0, segPerSide - 1 do
            local t = s / segPerSide
            local x = a[1] + (b[1] - a[1]) * t
            local z = a[2] + (b[2] - a[2]) * t
            table.insert(pts, {x, macRayGroundY(x, z), z})
        end
    end
    local c1 = corners[1]
    table.insert(pts, {c1[1], macRayGroundY(c1[1], c1[2]), c1[2]})
    return {points = pts, color = color, thickness = thickness or 0.06}
end

local function macBuildRing(centerPos, radius, color, thickness, ignoreObj)
    local nSeg = 64
    local pts = {}
    for i = 0, nSeg do
        local a = (i / nSeg) * 2 * math.pi
        local x = centerPos.x + radius * math.cos(a)
        local z = centerPos.z + radius * math.sin(a)
        local hits = Physics.cast({
            origin       = {x, centerPos.y + 10, z},
            direction    = {0, -1, 0},
            type         = 1,
            max_distance = 20,
        })
        local y = centerPos.y + 0.05
        for _, h in ipairs(hits) do
            if h.hit_object ~= ignoreObj then
                y = h.point.y + 0.05
                break
            end
        end
        table.insert(pts, {x, y, z})
    end
    return {points = pts, color = color, thickness = thickness or 0.05}
end

-- Stadium = rectangle with two semicircular caps on the long-axis ends.
-- halfLen, halfWid in inches (halfLen >= halfWid). dist = expansion outwards
-- from the base edge in inches (so the overlay sits at dist outside the base).
-- rotYdeg rotates the stadium around Y to match the fig's orientation; the
-- long axis is local Z (front-to-back of the model).
local function macBuildStadium(centerPos, halfLen, halfWid, rotYdeg, dist, color, thickness, ignoreObj)
    local rotRad = math.rad(rotYdeg or 0)
    local cosR, sinR = math.cos(rotRad), math.sin(rotRad)

    local capCenter = halfLen - halfWid   -- distance from center to cap arc center, along long axis
    local capR      = halfWid + dist      -- cap arc radius (= straight-side offset from long axis)

    local nSegArc = 32   -- segments per semicircle cap
    local pts     = {}

    local function addLocal(lx, lz)
        local wx = centerPos.x + lx * cosR + lz * sinR
        local wz = centerPos.z - lx * sinR + lz * cosR
        local hits = Physics.cast({
            origin       = {wx, centerPos.y + 10, wz},
            direction    = {0, -1, 0},
            type         = 1,
            max_distance = 20,
        })
        local y = centerPos.y + 0.05
        for _, h in ipairs(hits) do
            if h.hit_object ~= ignoreObj then
                y = h.point.y + 0.05
                break
            end
        end
        table.insert(pts, {wx, y, wz})
    end

    -- Top cap: angle 0 to pi (right edge -> top -> left edge), centered at z=+capCenter
    for i = 0, nSegArc do
        local a = (i / nSegArc) * math.pi
        addLocal(capR * math.cos(a), capCenter + capR * math.sin(a))
    end
    -- The straight left side is implicit: the polyline jumps from
    -- (-capR, +capCenter) directly to (-capR, -capCenter)  -  TTS draws a
    -- straight segment between consecutive points.
    -- Bottom cap: angle pi to 2pi, centered at z=-capCenter
    for i = 0, nSegArc do
        local a = math.pi + (i / nSegArc) * math.pi
        addLocal(capR * math.cos(a), -capCenter + capR * math.sin(a))
    end
    -- Close the loop back to the top-cap start point.
    addLocal(capR, capCenter)

    return {points = pts, color = color, thickness = thickness or 0.05}
end

local macBuilders = {}

macBuilders.range = function(fig, params)
    local pos = fig.getPosition()
    -- Resolve rangeKey for token-specific single-ring rendering (R button on
    -- a token). The hotkey path sets params.forceFigMode = true to bypass
    -- this and always render the fig-leader 6-band overlay, using the token's
    -- equivalent baseSize for sizing.
    local forceFig = params and params.forceFigMode
    local rangeKey = (not forceFig) and ((params and params.rangeKey) or fig.getVar("rangeKey")) or nil
    local config, decalURL, maxR, br
    local oblong, halfLen, halfWid, rotY
    local baseSize  -- hoisted: used below for firing-arc decision
    if rangeKey and RANGE_CONFIGS[rangeKey] then
        config   = RANGE_CONFIGS[rangeKey]
        decalURL = RANGE_DECAL_URLS[rangeKey]
        maxR     = RANGE_MAX_RADIUS[rangeKey]
        br       = TOKEN_BASE_RADIUS[rangeKey] or 0
    else
        baseSize = macGetBaseSize(fig)
        local hasBaseSize = baseSize ~= nil
        if not hasBaseSize then
            -- Token hit from hotkey: map rangeKey to base size for sizing.
            local tk = fig.getVar("rangeKey")
            baseSize = (tk and TOKEN_TO_BASESIZE[tk]) or "small"
        end
        config   = RANGE_CONFIGS[baseSize] or RANGE_CONFIGS.small
        decalURL = RANGE_DECAL_URLS.fig_leader[baseSize]
                   or RANGE_DECAL_URLS.fig_leader.small
        maxR     = RANGE_MAX_RADIUS.fig_leader
        if hasBaseSize then
            br = macFigBaseRadius(fig)
            local od = macOblongDims(fig, baseSize)
            if od then
                oblong, halfLen, halfWid, rotY = true, od.halfLen, od.halfWid, od.rotY
            end
        else
            -- Token in forceFig mode: use token's measured radius for offset.
            local tk = fig.getVar("rangeKey")
            br = (tk and TOKEN_BASE_RADIUS[tk]) or FIG_BASE_RADIUS_IN[baseSize] or 0.5315
        end
    end

    -- SWL convention: all distances are measured from the base/token edge.

    -- Vector contours: 6 concentric rings for round bases, 6 concentric
    -- stadium outlines for oblong bases (each band sits at band.r outwards
    -- from the base edge  -  same rule, just a different shape).
    local lines = {}
    for _, band in ipairs(config) do
        if oblong then
            table.insert(lines, macBuildStadium(pos, halfLen, halfWid, rotY, band.r,
                                                 RANGE_COLORS[band.c], 0.1, fig))
        else
            table.insert(lines, macBuildRing(pos, band.r + br, RANGE_COLORS[band.c], 0.1, fig))
        end
    end

    -- Firing arc lines (4 radial lines dividing into Front/R/Rear/L quadrants).
    -- Mirrors the vanilla Projector shader: ProjectorMaterial_<size> sets
    -- _Arc=1 / shader keyword _ARC_ON for every non-27mm base (medium, large,
    -- huge, laat, epic, long, snail). 27mm sets _Arc=0.
    -- Round bases : lines emanate from the base edge, radial from center.
    -- Oblong bases: lines emanate from the centers of the two end
    -- semicircles (front cap + rear cap), front lines at +/-45 from the
    -- long-axis forward, rear lines at +/-135.
    local arcColor = {1, 1, 1, 0.6}
    if baseSize and baseSize ~= "small" then
        if oblong then
            local capOffset = (halfLen or 0) - (halfWid or 0)
            local rad = math.rad(rotY)
            local fwdX, fwdZ = math.sin(rad), math.cos(rad)
            local frontX = pos.x + capOffset * fwdX
            local frontZ = pos.z + capOffset * fwdZ
            local rearX  = pos.x - capOffset * fwdX
            local rearZ  = pos.z - capOffset * fwdZ
            local reach  = (halfWid or 0) + (maxR or 6)
            local arcs = {
                {frontX, frontZ,  45},  -- front-right boundary
                {frontX, frontZ, -45},  -- front-left boundary
                {rearX,  rearZ,  135},  -- rear-right boundary
                {rearX,  rearZ, -135},  -- rear-left boundary
            }
            for _, e in ipairs(arcs) do
                local cx, cz, deg = e[1], e[2], e[3]
                local a = math.rad(rotY + deg)
                local sinA, cosA = math.sin(a), math.cos(a)
                table.insert(lines, {
                    points = {
                        {cx,                 pos.y + 0.1, cz},
                        {cx + reach * sinA,  pos.y + 0.1, cz + reach * cosA},
                    },
                    color = arcColor,
                    thickness = 0.05,
                })
            end
        else
            local figRotY = fig.getRotation().y
            local outerR  = (maxR or 6) + br
            for _, deg in ipairs({45, 135, 225, 315}) do
                local a = math.rad(deg + figRotY)
                local sinA, cosA = math.sin(a), math.cos(a)
                table.insert(lines, {
                    points = {
                        {pos.x + br * sinA,     pos.y + 0.1, pos.z + br * cosA},
                        {pos.x + outerR * sinA, pos.y + 0.1, pos.z + outerR * cosA},
                    },
                    color = arcColor,
                    thickness = 0.05,
                })
            end
        end
    end

    -- Decal halo (filled bands)  -  flat on the ground under the fig
    local hits = Physics.cast({
        origin       = {pos.x, pos.y + 10, pos.z},
        direction    = {0, -1, 0},
        type         = 1,
        max_distance = 20,
    })
    local groundY = pos.y
    for _, h in ipairs(hits) do
        if h.hit_object ~= fig then groundY = h.point.y; break end
    end

    if oblong then
        -- Stadium-shape PNGs are authored per oblong base size: the 6 bands
        -- inside the PNG already match the stadium vector outlines because
        -- the PNG was generated with the same halfWid/halfLen + dist math.
        -- Decal scale = footprint of the outermost band (2*(half + maxR))
        -- in each axis, so the PNG stretches to exactly the right size.
        local longSpan  = 2 * (halfLen + maxR)
        local shortSpan = 2 * (halfWid + maxR)
        return {
            lines  = lines,
            decals = {
                {
                    name     = "range_decal_" .. fig.getGUID(),
                    url      = decalURL,
                    position = {pos.x, groundY + 0.02, pos.z},
                    rotation = {90, rotY, 0},
                    scale    = {shortSpan, longSpan, 1},
                }
            },
        }
    end

    local effectiveMaxR = maxR + br
    return {
        lines  = lines,
        decals = {
            {
                name     = "range_decal_" .. fig.getGUID(),
                url      = decalURL,
                position = {pos.x, groundY + 0.02, pos.z},  -- below cohesion halo
                rotation = {90, 0, 0},
                scale    = {effectiveMaxR * 2, effectiveMaxR * 2, effectiveMaxR * 2},
            }
        },
    }
end

macBuilders.maxmove = function(fig, params)
    -- Use the anchor position stored at spawn time so the ring stays put
    -- when the fig slides toward the destination, instead of tracking it.
    local pos = (params and params.anchorPos) or fig.getPosition()
    local baseSize = (params and params.baseSize) or "small"
    local speed = (params and params.speed) or 1
    local radii = MAX_MOVE_RADIUS[baseSize] or MAX_MOVE_RADIUS.small
    local r = radii[speed] or radii[1]
    local color = {0.333, 0.800, 1.000, 0.7}
    -- Base ring: small white outline matching the figure's base
    -- (BB_MovementProjector renders a base ring on top of the cyan max-move).
    local br = FIG_BASE_RADIUS_IN[baseSize] or FIG_BASE_RADIUS_IN.small
    local baseColor = {1, 1, 1, 0.8}
    -- Oblong base dimensions for the stadium base ring. Use the rotation
    -- captured at spawn-time so the ring keeps its orientation even after
    -- the fig pivots toward its destination.
    local od = macOblongDims(fig, baseSize)
    local oblong = od ~= nil
    local halfLen, halfWid, rotY
    if oblong then
        halfLen, halfWid = od.halfLen, od.halfWid
        rotY = (params and params.anchorRot) or od.rotY
    end

    -- Ground raycast for decal position
    local hits = Physics.cast({
        origin       = {pos.x, pos.y + 10, pos.z},
        direction    = {0, -1, 0},
        type         = 1,
        max_distance = 20,
    })
    local groundY = pos.y
    for _, h in ipairs(hits) do
        if h.hit_object ~= fig then groundY = h.point.y; break end
    end

    if oblong then
        -- Oblong base: the cyan max-move envelope stays a round ring (isotropic
        --  -  any rotation reaches the same radius from the pivot), but the
        -- inner white base ring follows the rectangular footprint as a
        -- stadium hugging the actual base edge.
        return {
            lines = {
                macBuildRing(pos, r, color, 0.1, fig),
                macBuildStadium(pos, halfLen, halfWid, rotY, 0,
                                 baseColor, 0.06, fig),
            },
            decals = {
                {
                    name     = "maxmove_decal_" .. fig.getGUID(),
                    url      = MAX_MOVE_CYAN_URL,
                    position = {pos.x, groundY + 0.025, pos.z},
                    rotation = {90, 0, 0},
                    scale    = {r * 2, r * 2, r * 2},
                }
            },
        }
    end

    return {
        lines  = {
            macBuildRing(pos, r,  color,     0.1,  fig),  -- outer cyan max-move
            macBuildRing(pos, br, baseColor, 0.06, fig),  -- inner white base ring
        },
        decals = {
            {
                name     = "maxmove_decal_" .. fig.getGUID(),
                url      = MAX_MOVE_CYAN_URL,
                position = {pos.x, groundY + 0.025, pos.z},
                rotation = {90, 0, 0},
                scale    = {r * 2, r * 2, r * 2},
            }
        },
    }
end

macBuilders.deployment = function(_, params)
    local pos  = params.pos          -- {x, y, z} cell center (after offset)
    local cell = params.cell         -- "r"/"b"/"rh"/... key
    local size = DEPLOYMENT_CELL_SIZES[cell] or {6, 6}
    local w, d = size[1], size[2]
    local cx, cz = pos[1], pos[3]
    local hw, hd = w / 2, d / 2

    local isRed = cell:sub(1, 1) == "r"
    local lineColor = isRed and {1, 0.15, 0.15, 0.9} or {0.15, 0.4, 1, 0.9}
    local url = isRed and DEPLOYMENT_RED_URL or DEPLOYMENT_BLUE_URL

    local groundY = macRayGroundY(cx, cz, 0)

    return {
        lines = { macBuildRect(cx, cz, hw, hd, lineColor, 0.08) },
        decals = {
            {
                name     = "deployment_decal_" .. cell .. "_" .. tostring(cx) .. "_" .. tostring(cz),
                url      = url,
                position = {cx, groundY + 0.03, cz},
                rotation = {90, 0, 0},
                scale    = {w, d, 1},
            }
        },
    }
end

macBuilders.cohesion = function(fig, params)
    local pos      = fig.getPosition()
    -- Cohesion overlay = base edge + 3 inches (half Range 1). Round bases get
    -- a ring; oblong bases (long/snail) get a stadium-shape concentric to the
    -- footprint so the offset stays a constant 3" from the edge.
    local rangeKey = fig.getVar("rangeKey")
    local oblong, halfLen, halfWid, rotY, r
    if rangeKey and TOKEN_BASE_RADIUS[rangeKey] then
        r = TOKEN_BASE_RADIUS[rangeKey] + 3.0
    else
        local baseSize = macGetBaseSize(fig) or "small"
        local od = macOblongDims(fig, baseSize)
        if od then
            oblong, halfLen, halfWid, rotY = true, od.halfLen, od.halfWid, od.rotY
        else
            r = (FIG_BASE_RADIUS_IN[baseSize] or FIG_BASE_RADIUS_IN.small) + 3.0
        end
    end
    if params and params.radius then
        oblong, r = false, params.radius
    end

    -- Find ground level under the fig so the flat decal sits on the table,
    -- not at the fig pivot (which is above the base).
    local hits = Physics.cast({
        origin       = {pos.x, pos.y + 10, pos.z},
        direction    = {0, -1, 0},
        type         = 1,
        max_distance = 20,
    })
    local groundY = pos.y
    for _, h in ipairs(hits) do
        if h.hit_object ~= fig then
            groundY = h.point.y
            break
        end
    end

    if oblong then
        -- Halo decal: stretch the round halo PNG into an ellipse aligned with
        -- the fig's long axis. Approximates the stadium fade (a true stadium
        -- halo would need a custom PNG); good enough visually since the
        -- vector stadium outline carries the precise boundary.
        local longSpan  = 2 * (halfLen + 3.0)
        local shortSpan = 2 * (halfWid + 3.0)
        return {
            lines  = { macBuildStadium(pos, halfLen, halfWid, rotY, 3.0,
                                        {1, 1, 1, 0.8}, 0.06, fig) },
            decals = {
                {
                    name     = "cohesion_halo_" .. fig.getGUID(),
                    url      = COHESION_HALO_URL,
                    position = {pos.x, groundY + 0.04, pos.z},
                    -- 90 deg pitch lays the decal flat on the table; rotY (yaw)
                    -- aligns its local Y with the fig's long axis.
                    rotation = {90, rotY, 0},
                    scale    = {shortSpan, longSpan, 1},
                }
            },
        }
    end

    return {
        lines  = { macBuildRing(pos, r, {1, 1, 1, 0.8}, 0.06, fig) },
        decals = {
            {
                name     = "cohesion_halo_" .. fig.getGUID(),
                url      = COHESION_HALO_URL,
                position = {pos.x, groundY + 0.04, pos.z},
                rotation = {90, 0, 0},
                scale    = {r * 2, r * 2, r * 2},
            }
        },
    }
end

function macRedrawAll()
    local lines, decals = {}, {}
    -- Preload all texture URLs (invisible decals far below the table) so TTS
    -- keeps them cached and we never get the white-square flash on respawn.
    local preloadURLs = {
        COHESION_HALO_URL,
        RANGE_DECAL_URLS.smokeToken,
        RANGE_DECAL_URLS.token, RANGE_DECAL_URLS.tokenRangeTwo,
        RANGE_DECAL_URLS.poi, RANGE_DECAL_URLS.bombCart,
        RANGE_DECAL_URLS.fig_leader.small, RANGE_DECAL_URLS.fig_leader.medium,
        RANGE_DECAL_URLS.fig_leader.large, RANGE_DECAL_URLS.fig_leader.huge,
        RANGE_DECAL_URLS.fig_leader.laat,  RANGE_DECAL_URLS.fig_leader.epic,
        RANGE_DECAL_URLS.fig_leader.long,  RANGE_DECAL_URLS.fig_leader.snail,
        MAX_MOVE_CYAN_URL,
        DEPLOYMENT_RED_URL, DEPLOYMENT_BLUE_URL,
    }
    for i, url in ipairs(preloadURLs) do
        table.insert(decals, {
            name     = "preload_" .. i,
            url      = url,
            position = {0, -200 - i * 0.01, 0},
            rotation = {90, 0, 0},
            scale    = {0.01, 0.01, 0.01},
        })
    end
    local stale = {}
    for key, entry in pairs(activeOverlays) do
        local b = macBuilders[entry.type]
        if b then
            -- Deployment entries have no fig (params-driven). Others need a
            -- live Object  -  drop them silently if destroyed/invalid.
            local needsFig = (entry.type ~= "deployment")
            if needsFig and (not entry.fig
                             or type(entry.fig.getPosition) ~= "function") then
                stale[#stale + 1] = key
            else
                local ok, out = pcall(b, entry.fig, entry.params)
                if ok and out then
                    for _, l in ipairs(out.lines or {}) do
                        table.insert(lines, l)
                    end
                    for _, d in ipairs(out.decals or {}) do
                        table.insert(decals, d)
                    end
                else
                    stale[#stale + 1] = key
                end
            end
        end
    end
    for _, k in ipairs(stale) do activeOverlays[k] = nil end
    Global.setVectorLines(lines)
    Global.setDecals(decals)
end

function gSpawnCohesion(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    activeOverlays[fig.getGUID() .. ":cohesion"] = {
        type = "cohesion", fig = fig, params = params or {}
    }
    macRedrawAll()
end

function gClearCohesion(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    activeOverlays[fig.getGUID() .. ":cohesion"] = nil
    macRedrawAll()
end

function gToggleCohesion(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    local key = fig.getGUID() .. ":cohesion"
    if activeOverlays[key] then
        gClearCohesion(params)
    else
        gSpawnCohesion(params)
    end
end

-- Range polling: a slow timer (5 frames = ~12 fps) that re-draws active
-- range rulers so they follow figures in real-time. Stops automatically when
-- no range overlay is active anymore  -  avoids the overnight memory leak.
macRangePollingActive = macRangePollingActive or false

function macRangePoll()
    local hasRange = false
    for _, e in pairs(activeOverlays) do
        if e.type == "range" then hasRange = true; break end
    end
    if hasRange then
        macRedrawAll()
        Wait.frames(macRangePoll, 5)
    else
        macRangePollingActive = false
    end
end

function gSpawnRange(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    activeOverlays[fig.getGUID() .. ":range"] = {
        type = "range", fig = fig, params = params or {}
    }
    macRedrawAll()
    if not macRangePollingActive then
        macRangePollingActive = true
        Wait.frames(macRangePoll, 5)
    end
end

function gClearRange(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    activeOverlays[fig.getGUID() .. ":range"] = nil
    macRedrawAll()
end

function gToggleRange(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    local key = fig.getGUID() .. ":range"
    if activeOverlays[key] then
        gClearRange(params)
    else
        gSpawnRange(params)
    end
end

function gSpawnDeployment(params)
    -- params: { cell = "r" | "b" | ..., pos = {x, y, z} }
    if not params or not params.cell or not params.pos then return end
    local key = "deploy:" .. params.cell .. ":"
              .. tostring(params.pos[1]) .. ":" .. tostring(params.pos[3])
    activeOverlays[key] = {type = "deployment", fig = nil, params = params}
    macRedrawAll()
end

function gClearAllDeployment()
    for k, e in pairs(activeOverlays) do
        if e.type == "deployment" then activeOverlays[k] = nil end
    end
    macRedrawAll()
end

function gSpawnMaxMove(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    -- Capture the spawn-time position + yaw. MaxMove is anchored to where
    -- the move STARTED  -  it must not follow the fig as it slides toward
    -- the destination. The yaw matters for oblong stadium overlays so the
    -- white base ring keeps its orientation while the fig pivots.
    local p = (params and params.params) or params or {}
    p.anchorPos = fig.getPosition()
    p.anchorRot = fig.getRotation().y
    activeOverlays[fig.getGUID() .. ":maxmove"] = {
        type = "maxmove", fig = fig, params = p
    }
    macRedrawAll()
end

function gClearMaxMove(params)
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    activeOverlays[fig.getGUID() .. ":maxmove"] = nil
    macRedrawAll()
end

function onObjectPickUp(player_color, obj)
    if not obj or not obj.getGUID then return end
    local guid = obj.getGUID()
    local prefix = guid .. ":"
    local plen = #prefix
    local changed = false
    for key, entry in pairs(activeOverlays) do
        if key:sub(1, plen) == prefix then
            -- Cohesion: static, hide during pickup, restore on drop.
            -- Range: keep visible; the polling timer redraws each tick so
            -- the ruler follows the figure in real-time during the drag.
            if entry.type == "cohesion" then
                hiddenWhilePickedUp[key] = entry
                activeOverlays[key] = nil
                changed = true
            end
        end
    end
    if changed then macRedrawAll() end
end

function onObjectDrop(player_color, obj)
    if not obj or not obj.getGUID then return end
    local guid = obj.getGUID()
    local prefix = guid .. ":"
    local plen = #prefix

    -- Defer the overlay restore until the fig has come to rest. Without this,
    -- a flick-drop with residual inertia leaves the overlay anchored at the
    -- release position while the fig continues to slide across the table.
    local function tryRestore()
        local fig = getObjectFromGUID(guid)
        if not fig then return end  -- destroyed during slide
        if fig.held_by_color then return end  -- picked up again, hold off
        local v = fig.getVelocity and fig.getVelocity()
        if v then
            local speed = math.sqrt((v.x or 0)^2 + (v.y or 0)^2 + (v.z or 0)^2)
            if speed > 0.05 then
                Wait.frames(tryRestore, 3)
                return
            end
        end
        local changed = false
        for key, entry in pairs(hiddenWhilePickedUp) do
            if key:sub(1, plen) == prefix then
                activeOverlays[key] = entry
                hiddenWhilePickedUp[key] = nil
                changed = true
            end
        end
        if changed then macRedrawAll() end
    end
    tryRestore()
end

function onObjectDestroy(obj)
    if not obj or not obj.getGUID then return end
    local guid = obj.getGUID()
    local prefix = guid .. ":"
    local plen = #prefix
    local changed = false
    for key in pairs(activeOverlays) do
        if key:sub(1, plen) == prefix then
            activeOverlays[key] = nil
            changed = true
        end
    end
    for key in pairs(hiddenWhilePickedUp) do
        if key:sub(1, plen) == prefix then
            hiddenWhilePickedUp[key] = nil
        end
    end
    if changed then macRedrawAll() end
end

-- Texture preload is handled by macRedrawAll which always includes all PNG
-- URLs as invisible decals far below the table. No separate preload needed.

-- ============================================
-- PER-SEAT MODE TOGGLE (Cohesion + Range)
-- Each seated player picks their renderer: "mac" (this patch) or
-- "windows" (original bundle Projector). When a player triggers an overlay,
-- the router checks THEIR mode and uses that renderer. The rendered overlay
-- is visible to everyone (TTS engine limitation).
-- ============================================

playerOverlayMode = playerOverlayMode or {}  -- color -> "mac" | "windows"
-- Default = "windows" (majority of TTS users). Mac users toggle their seat
-- via the floating panel. Same for deployment (table-wide setting).
deploymentMode    = deploymentMode    or "windows"

function gGetMode(params)
    return playerOverlayMode[params.color] or "windows"
end

function gGetDeploymentMode()
    return deploymentMode
end

function gToggleDeploymentMode()
    deploymentMode = (deploymentMode == "mac") and "windows" or "mac"
    -- Wipe any active deployment zones so the next setup uses the new mode.
    gClearAllDeployment()
    macRefreshModeUI()
end

-- Replicates the original showRangeOnHoveredModel toggle, calling the
-- aliased Global originals so our Mac overrides don't recapture the path.
function gWindowsRangeToggle(fig)
    if not fig then return end
    if rangeRuler ~= nil then
        pcall(clearRangeRulersOriginalGlobal)
        if selectedUnitObj == fig then
            selectedUnitObj = nil
            return
        end
    end
    if fig.interactable then
        pcall(function() spawnRangeRulerOriginalGlobal(fig) end)
        selectedUnitObj = fig
    end
end

-- Replicates the original showCohesionOnHoveredModel toggle. Uses Global
-- aliased originals + Global cohesionRuler state (set by the original).
function gWindowsCohesionToggle(fig)
    if not fig then return end
    if fig.interactable and selectedUnitObj == fig and cohesionRuler ~= nil then
        pcall(clearCohesionRulerOriginalGlobal)
        selectedUnitObj = nil
        return
    end
    pcall(clearCohesionRulerOriginalGlobal)
    pcall(function() spawnCohesionRulerOriginalGlobal(fig) end)
    selectedUnitObj = fig
end

function gCohesionTrigger(params)
    if not params or not params.figGUID then return end
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    local mode = playerOverlayMode[params.playerColor] or "windows"
    if mode == "windows" then
        gWindowsCohesionToggle(fig)
    else
        gToggleCohesion({figGUID = params.figGUID})
    end
end

function gRangeTrigger(params)
    if not params or not params.figGUID then return end
    local fig = getObjectFromGUID(params.figGUID)
    if not fig then return end
    local mode = playerOverlayMode[params.playerColor] or "windows"
    if mode == "windows" then
        gWindowsRangeToggle(fig)
    else
        gToggleRange({
            figGUID      = params.figGUID,
            forceFigMode = params.forceFigMode,
            rangeKey     = params.rangeKey,
        })
    end
end

-- UI: floating panel with one toggle button per seated player
function macModeClick(player, _, id)
    local color = id:sub(9)  -- "macmode_Red" -> "Red"
    if player.color ~= color then
        broadcastToColor("Only the player at this seat can toggle their mode.",
                         player.color, {1, 0.5, 0.5})
        return
    end
    local cur = playerOverlayMode[color] or "windows"
    playerOverlayMode[color] = (cur == "mac") and "windows" or "mac"
    -- Wipe Mac-side overlays so stale visuals don't linger after the toggle.
    -- We don't track per-color ownership, so this clears Cohesion+Range for
    -- everyone  -  acceptable since each player can re-trigger their hotkey.
    -- Windows-side overlays (fig-scoped cohesionRuler/rangeRuler) are
    -- cleared by iterating objects with active state.
    for k, e in pairs(activeOverlays) do
        if e.type == "cohesion" or e.type == "range" then
            activeOverlays[k] = nil
        end
    end
    macRedrawAll()
    for _, obj in ipairs(getAllObjects()) do
        if obj.getVar and obj.getVar("cohesionRuler") then
            pcall(function() obj.call("clearCohesionRulerOriginal", obj) end)
        end
        if obj.getVar and obj.getVar("rangeRuler") then
            pcall(function() obj.call("clearRangeRulersOriginal", obj) end)
        end
    end
    macRefreshModeUI()
end

local function macFindNodeById(tree, id)
    for _, node in ipairs(tree) do
        if node.attributes and node.attributes.id == id then return node, tree end
        if node.children then
            local found, parent = macFindNodeById(node.children, id)
            if found then return found, parent end
        end
    end
    return nil, nil
end

-- Tracks the panel's desired active state across refreshes. Persists so a
-- click on the close X before the initial refresh is honored. Hidden at first
-- load (default = false); the floating "Mac Patch" menu button reveals it.
macModePanelActive = (macModePanelActive == nil) and false or macModePanelActive

function macModeToggleVisibility()
    macModePanelActive = not macModePanelActive
    local tree = UI.getXmlTable() or {}
    local panel = macFindNodeById(tree, "macModePanel")
    if panel then
        panel.attributes.active = macModePanelActive and "true" or "false"
        UI.setXmlTable(tree)
    else
        macRefreshModeUI()
    end
end

function macRefreshModeUI()
    local seated = Player.getPlayers()
    local rows = {{
        tag = "Panel",
        attributes = {
            color = "transparent",
            preferredHeight = "24",
        },
        children = {
            {
                tag = "Text",
                attributes = {
                    text = "Mac TTS U6 Patch",
                    fontSize = "16",
                    color = "white",
                    alignment = "MiddleLeft",
                    rectAlignment = "MiddleLeft",
                },
            },
            {
                tag = "Button",
                attributes = {
                    id = "macModePanelClose",
                    text = "X",
                    onClick = "macModeToggleVisibility",
                    color = "#3a1e1e",
                    textColor = "white",
                    fontSize = "12",
                    width = "24",
                    height = "20",
                    rectAlignment = "MiddleRight",
                },
            },
        },
    }, {
        tag = "Text",
        attributes = {
            text = "Cohesion & Range: pick your renderer",
            fontSize = "12",
            color = "#bbbbbb",
            alignment = "MiddleCenter",
        },
    }}
    if #seated == 0 then
        table.insert(rows, {
            tag = "Text",
            attributes = {
                text = "(no seated players)",
                fontSize = "12",
                color = "#888888",
                alignment = "MiddleCenter",
            },
        })
    end
    for _, p in ipairs(seated) do
        local mode = playerOverlayMode[p.color] or "windows"
        local label = p.color .. " - " ..
                      (mode == "mac" and "MAC FALLBACK" or "WINDOWS ORIGINAL")
        local bg = (mode == "mac") and "#1e7a3a" or "#7a3a1e"
        table.insert(rows, {
            tag = "Button",
            attributes = {
                id = "macmode_" .. p.color,
                text = label,
                onClick = "macModeClick",
                color = bg,
                fontSize = "13",
                textColor = "white",
                preferredHeight = "28",
            },
        })
    end
    -- Deployment is table-wide (everyone sees the same zones); use a single
    -- global toggle rather than per-seat.
    table.insert(rows, {
        tag = "Text",
        attributes = {
            text = "Deployment (table-wide)",
            fontSize = "12",
            color = "#bbbbbb",
            alignment = "MiddleCenter",
        },
    })
    table.insert(rows, {
        tag = "Button",
        attributes = {
            id   = "macmode_deployment",
            text = (deploymentMode == "mac") and "DEPLOYMENT: MAC FALLBACK"
                                              or "DEPLOYMENT: WINDOWS ORIGINAL",
            onClick = "macDeploymentClick",
            color   = (deploymentMode == "mac") and "#1e3a7a" or "#7a3a1e",
            fontSize = "13",
            textColor = "white",
            preferredHeight = "28",
        },
    })
    -- Build my panel (will be merged into the existing UI tree below so we
    -- don't clobber legionFloatingMenu / Welcome / Chess Clocks etc.).
    local panel = {
        tag = "Panel",
        attributes = {
            id = "macModePanel",
            active = macModePanelActive and "true" or "false",
            rectAlignment = "MiddleRight",
            offsetXY = "-10 80",
            width = "260",
            height = "320",
            color = "rgba(0.06,0.06,0.06,0.9)",
            padding = "8 8 8 8",
            outlineSize = "1 1",
            outline = "#303030",
        },
        children = {{
            tag = "VerticalLayout",
            attributes = {
                spacing = "4",
                childForceExpandHeight = "false",
                childForceExpandWidth = "true",
            },
            children = rows,
        }},
    }

    local tree = UI.getXmlTable() or {}
    -- Remove any stale macModePanel before reinserting the fresh one.
    for i = #tree, 1, -1 do
        if tree[i].attributes and tree[i].attributes.id == "macModePanel" then
            table.remove(tree, i)
        end
    end
    table.insert(tree, panel)

    -- Inject a "Mac Patch" button into the bottom-right legionFloatingMenu
    -- (replaces the first interactable=false placeholder button).
    local menu = macFindNodeById(tree, "legionFloatingMenu")
    if menu and menu.children then
        local hasMine = false
        for _, c in ipairs(menu.children) do
            if c.attributes and c.attributes.id == "macModeMenuButton" then
                hasMine = true; break
            end
        end
        if not hasMine then
            for i, c in ipairs(menu.children) do
                if c.attributes and c.attributes.interactable == "false" then
                    menu.children[i] = {
                        tag = "Button",
                        attributes = {
                            id = "macModeMenuButton",
                            fontSize = "10",
                            onClick = "macModeToggleVisibility",
                            tooltip = "Toggle Mac TTS U6 Patch panel",
                        },
                        value = "Mac Patch",
                    }
                    break
                end
            end
        end
    end

    UI.setXmlTable(tree)
end

function macDeploymentClick(_, _, _)
    gToggleDeploymentMode()
end

-- Defer one frame: TTS throws a UTF-8 buffer encoding error if we rebuild
-- the XML synchronously inside these handlers (engine race during seat
-- change finalization). pcall guards against any residual issue.
local function macDeferRefresh()
    Wait.frames(function() pcall(macRefreshModeUI) end, 1)
end
function onPlayerChangeColor(_)    macDeferRefresh() end
function onPlayerConnect(_)        macDeferRefresh() end
function onPlayerDisconnect(_)     macDeferRefresh() end

Wait.time(macRefreshModeUI, 2)

-- Override hotkey init functions to capture playerColor and route through
-- the per-seat trigger. Defining initCohesionHotkeys/initRangebandHotkeys
-- here SHADOWS the originals  -  when the original onLoad runs init*(), our
-- versions register the hotkey instead.

function initCohesionHotkeys()
    addHotkey("Show Cohesion On Hovered Model",
        function(playerColor, hoverObject, _)
            if not hoverObject or not hoverObject.interactable then return end
            gCohesionTrigger({
                figGUID     = hoverObject.getGUID(),
                playerColor = playerColor,
            })
        end)
end

function initRangebandHotkeys()
    addHotkey("Show Range On Hovered Model",
        function(playerColor, hoverObject, _)
            if not hoverObject or not hoverObject.interactable then return end
            gRangeTrigger({
                figGUID      = hoverObject.getGUID(),
                playerColor  = playerColor,
                forceFigMode = true,  -- hotkey always shows 6-band fig overlay
            })
        end)
end

-- The vanilla showRangeOnHoveredModel calls spawnRangeRuler(fig) which spawns
-- the Range AssetBundle directly. On Mac, the "Oblong Range" shader used by
-- long/snail bundles isn't supported (magenta). Override the global function
-- to route through gToggleRange so our stadium overlay renders instead.
-- Vanilla Range bundle still works for round bases via gWindowsRangeToggle
-- when the player explicitly chose Windows mode.
function showRangeOnHoveredModel(hoverObject)
    if not hoverObject or not hoverObject.interactable then return end
    gToggleRange({figGUID = hoverObject.getGUID(), forceFigMode = true})
end

-- Note: we deliberately do NOT override the global spawnRangeRuler /
-- clearRangeRulers / showRangeOnHoveredModel chain at the Lua scope where
-- the vanilla mod defines it. Overriding spawnRangeRuler from a token
-- script reproducibly SIGSEGV'd TTS on Mac in May 2026 (Mono GC stack
-- corruption). Mac routing happens via the g* functions called from our
-- own hotkey/button wrappers; the originals stay reachable for
-- Windows-mode players via spawnRangeRulerOriginalGlobal aliases above.

-- END MAC COHESION FALLBACK
"""


# ------------------------------------------------------------
# 2) Wrapper appended AFTER the original Cohesion include (per-seat router)
# ------------------------------------------------------------
# Strategy: keep the ORIGINAL Cohesion/RangeRulers expansion intact, then
# append wrappers that alias originals + route through the Global router.
# This preserves the original Custom_AssetBundle Projector spawn for
# Windows-mode players (called back as spawnCohesionRulerOriginal).

COHESION_WRAPPER = r"""
-- MAC PATCH per-seat router (Cohesion)
-- Aliases the original spawn so Windows-mode players still get their bundle.
spawnCohesionRulerOriginal = spawnCohesionRuler
clearCohesionRulerOriginal = clearCohesionRuler

function spawnCohesionRuler(cohesionSourceObject)
    if not cohesionSourceObject then return end
    Global.call("gCohesionTrigger", {
        figGUID     = cohesionSourceObject.getGUID(),
        playerColor = nil,
    })
end

function clearCohesionRuler()
    if self and self.getGUID and self.getGUID() ~= "-1" then
        Global.call("gClearCohesion", { figGUID = self.getGUID() })
    end
    if cohesionRuler ~= nil then
        pcall(clearCohesionRulerOriginal)
    end
end

-- Vanilla Order Token's clearTemplates() calls clearCohesionRulers (plural),
-- but the save was built from an older mod version that ships only the
-- singular clearCohesionRuler. Provide the plural as a delegating stub so
-- standby/clearTemplates/etc. don't nil-error on click.
function clearCohesionRulers()
    if selectedUnitObj then
        pcall(function() selectedUnitObj.setVar("moveState", false) end)
        pcall(function() selectedUnitObj.call("clearCohesionRuler") end)
    end
end

-- Same root cause as clearCohesionRulers: newer Order Token code paths in
-- the live save (e.g. moveUnit -> stopAttack) call helpers the older bundled
-- script doesn't ship. Stub them so MOVE/AIM/etc don't nil-error. The bodies
-- mirror the current vanilla source but pcall every dependency so we don't
-- chain-error if anything else is also missing.
function clearAttackLine()
    if attackLine then
        for k, v in pairs(attackLine) do
            pcall(destroyObject, v)
        end
        attackLine = nil
    end
end

function exitTargetingMode()
    enemyHighlighted = false
    attackModeOn = false
    pcall(clearRangeRulers)
    pcall(unhighlightEnemies)
    pcall(clearAttackLine)
end

function exitAttackMode()
    enemyHighlighted = false
    attackModeOn = false
    pcall(clearRangeRulers)
    pcall(unhighlightEnemies)
end
-- END MAC PATCH per-seat router (Cohesion)
"""


COHESION_BLOCK_RE = re.compile(
    r"----#include !/Cohesion\r?\n.*?----#include !/Cohesion\r?\n",
    re.DOTALL
)

RANGE_BLOCK_RE = re.compile(
    r"----#include !/RangeRulers\r?\n.*?----#include !/RangeRulers\r?\n",
    re.DOTALL
)

# Maximum Move spawn block in Order_Token (a57c41), inline (not an include).
# Captures from `local maxMoveBundles = getMovementLinks()` up to and
# including the two closing ends of the original `if isDeploy / if ... ~= nil`
# scaffold. The replacement is self-contained (opens 3 ifs, closes all 3),
# so re-applying yields the same canonical block  -  idempotent. (Earlier
# versions only matched up to setName("Maximum Move") and re-matched their
# own output, accumulating orphan else/end copies on each re-run.)
MAXMOVE_SPAWN_RE = re.compile(
    r"local maxMoveBundles = getMovementLinks\(\).*?"
    r"\r?\n        end\r?\n    end\r?\n",
    re.DOTALL
)

MAXMOVE_SPAWN_REPLACEMENT = r"""local maxMoveBundles = getMovementLinks()
    local baseSizeMoveBundles = maxMoveBundles[unitData.baseSize]
    local maxMoveTemplateBundleToSpawn = baseSizeMoveBundles and baseSizeMoveBundles[unitData.selectedSpeed]

    -- MAC PATCH: permissive condition (covers nil + false) so the overlay
    -- also fires when changeSpeed2/3 calls moveUnit() with no isDeploy arg.
    if isDeploy ~= true then
        if maxMoveTemplateBundleToSpawn ~= nil then
            local _macMode = Global.call("gGetMode", {color = macActivePlayerForMove})
            if _macMode == "windows" then
                -- WINDOWS ORIGINAL: spawn Custom_AssetBundle Projector
                maxMoveTemplate = spawnObject({
                    type = "Custom_AssetBundle",
                    position = {basePos.x, basePos.y + 20, basePos.z},
                    rotation = {0, basePos.y, 0},
                    scale = {0,0,0}
                })
                maxMoveTemplate.setCustomObject({
                    type = 0,
                    assetbundle = maxMoveTemplateBundleToSpawn
                })
                maxMoveTemplate.setLock(true)
                maxMoveTemplate.use_gravity = false
                maxMoveTemplate.setName("Maximum Move")
            else
                -- MAC FALLBACK: route through the Global Overlays manager
                Global.call("gSpawnMaxMove", {
                    figGUID  = selectedUnitObj.getGUID(),
                    baseSize = unitData.baseSize,
                    speed    = unitData.selectedSpeed,
                })
                maxMoveTemplate = nil
            end
        end
    end
"""

# clearMovementTemplates function: needs to also clear our managed maxmove
# overlay. We replace the whole function body.
# Match up to the first un-indented `end` (= the function's closing end), so
# the regex is idempotent  -  it matches both the vanilla body and any
# previously patched body shape (which has extra lines past the inner `end`).
CLEAR_MOVEMENT_RE = re.compile(
    r"function clearMovementTemplates\(\).*?\r?\nend\b",
    re.DOTALL
)

CLEAR_MOVEMENT_REPLACEMENT = r"""function clearMovementTemplates()
    if templateA ~= nil then
        destroyObject(templateA)
    end
    if templateB ~= nil then
        destroyObject(templateB)
    end
    -- MAC PATCH per-seat: destroy bundle Object if present (Windows-mode
    -- spawn) AND clear the manager entry (Mac fallback). Either may be set.
    if maxMoveTemplate ~= nil then
        pcall(destroyObject, maxMoveTemplate)
    end
    -- Clear only THIS token's MaxMove (keyed by the attached unit), not
    -- everyone's  -  gClearAllMaxMove was killing other tokens' rings when
    -- two players had MOVE open at the same time.
    if selectedUnitObj then
        Global.call("gClearMaxMove", { figGUID = selectedUnitObj.getGUID() })
    end
    maxMoveTemplate = nil
end"""

# Deployment Boundary: replace the Custom_AssetBundle Projector spawn inside
# spawnBoundaryCell (SETUP_CONTROLLER 1cb552) with a Global.call to the manager.
# Idempotent: matches both the vanilla form AND a previously-injected patched
# form (between the MAC PATCH dual-path marker and the closing `  end`). The
# patched alternative is listed first so re-runs prefer it.
DEPLOYMENT_SPAWN_RE = re.compile(
    r"(?:"
    r"-- MAC PATCH dual-path:.*?\r?\n  end"
    r"|"
    r"local projector = spawnObject\(\{\r?\n"
    r"    type        = \"Custom_AssetBundle\",.*?"
    r"projector\.setCustomObject\(\{\r?\n"
    r"    assetbundle = asset,\r?\n"
    r"  \}\)"
    r")",
    re.DOTALL
)

DEPLOYMENT_SPAWN_REPLACEMENT = r"""-- MAC PATCH dual-path: branch on the table-wide deploymentMode toggle.
  local _macDeployMode = Global.call("gGetDeploymentMode")
  local projector = nil
  if _macDeployMode == "windows" then
    projector = spawnObject({
      type        = "Custom_AssetBundle",
      position    = pos,
      scale       = {0, 0, 0},
      rotation    = {0, deployRotations[cell], 0}
    })
    projector.setName("Deployment Boundary")
    projector.setLock(true)
    projector.setCustomObject({
      assetbundle = asset,
    })
  else
    Global.call("gSpawnDeployment", { cell = cell, pos = pos })
  end"""

# clearDeploymentBoundary: also clear manager entries.
CLEAR_DEPLOYMENT_RE = re.compile(
    r"function clearDeploymentBoundary\(\)\r?\n"
    r"    local battlefieldObjs = battlefieldZone\.getObjects\(\).*?\r?\n"
    r"    end\r?\nend",
    re.DOTALL
)

CLEAR_DEPLOYMENT_REPLACEMENT = r"""function clearDeploymentBoundary()
    -- MAC PATCH: clear Global Overlays manager entries first.
    Global.call("gClearAllDeployment", {})
    local battlefieldObjs = battlefieldZone.getObjects()
    for _, obj in pairs(battlefieldObjs) do
        if obj.getName() == "Deployment Boundary" then
            destroyObject(obj)
        end
    end
end"""

# Silhouette URL swap to our Unity-6-compiled bundle.
#
# The upstream BucketheadBits_Silhouette bundle uses Allen White's custom
# Silhouette shader compiled under Unity 2019.4. TTS U6 on Mac fails to
# load that shader at runtime (console: "Shader didn't load correctly for
# AssetBundle material BucketheadBits_Silhouette. Assigning Standard
# shader.") and falls back to Standard, which renders the cylinder opaque.
#
# Our fork-hosted bundle uses the SAME prefab + material + shader source
# (Assets/Sihl/), only the compile target differs (Unity 6 instead of
# Unity 2019.4). Path A from Dicewrench's analysis.
#
# We swap ALL silhouette URLs (default cylinder, snail, long) to the same
# fork URL. Snail/long visual fidelity is acceptable for now (cylinder
# placeholder); per-base meshes are a separate follow-up.
SILHOUETTE_BUNDLE_URL = (
    "https://raw.githubusercontent.com/ironsquadronfr-hub/tts/"
    "mac-projector-fallback/mod/data/mac-fallback-assets/"
    "silhouette_mac_fallback.unity3d"
)
SILHOUETTE_URL_RE = re.compile(
    r'(silhouetteData\s*=\s*)"https?://[^"]*/ugc/[^"]+"'
)
SILHOUETTE_URL_REPLACEMENT = r'\1"' + SILHOUETTE_BUNDLE_URL + '"'


# Cleanup of debug prints and corrupted signatures from earlier sessions.
# Safe no-op on a clean save. Matches both the legacy `print("[SIL DEBUG] ...)`
# form AND the chat-visible `printToAll("[SIL] ...", {...})` form.
SIL_DEBUG_STRIP_RE = re.compile(
    # Match leading horizontal whitespace only (NOT \s* which would also eat
    # the newline before, mashing the function signature against the next
    # statement  -  that was a real bug we hit earlier this session).
    r'[ \t]*(?:print\("\[SIL DEBUG\][^\n]*\)|'
    r'printToAll\("\[SIL\][^"]*",\s*\{[^}]*\}\))\r?\n'
)
# Repair function signatures that were mashed by the previous \s*-glob bug.
# Idempotent: target the specific mashed patterns; matches are zero on a
# clean save.
SIL_REPAIR_TOGGLE_RE = re.compile(
    r'(function toggleSilhouettes\(\))(  if silhouetteState then)'
)
SIL_REPAIR_SHOW_RE = re.compile(
    r'(function showSilhouette\(\))(  for k, guid in pairs\(miniGUIDs)'
)
SIL_REPAIR_SPAWN_RE = re.compile(
    r'(function spawnSilhouette\(obj, pos, rot\))(  local globals)'
)


# Silhouette state-desync fix (upstream bug).
#
# Upstream clearSilhouette assumes removeAttachments()[1] always returns an
# object, but the state variable `silhouetteState` is persisted across saves
# while the physical attachments are not  -  so a save made with silhouettes
# visible reloads with state=true but no attachments. First SIL click then
# calls clearSilhouette which dereferences nil and crashes.
#
# Two-part patch:
#   (1) clearSilhouette: guard the nil case (skip the destruct if no
#       attachment), so re-clicks don't crash.
#   (2) onload: force silhouetteState=false on every load, since the load
#       cannot restore the physical silhouettes anyway.
#
# Also fixes the "two silhouettes stacked" symptom: that happens when
# showSilhouette runs while state is desynced, spawning a second set on top
# of one whose handles have been forgotten.
CLEAR_SILHOUETTE_RE = re.compile(
    r"function clearSilhouette\(\).*?silhouetteState = false\r?\nend",
    re.DOTALL
)
CLEAR_SILHOUETTE_REPLACEMENT = r"""function clearSilhouette()
  -- MAC PATCH: guard nil silToDestroy. silhouetteState can be persisted as
  -- true across saves while the physical attachments are not, so a load
  -- with state=true + no attachments would otherwise crash here.
  for k, guid in pairs(miniGUIDs or {}) do
    local obj = getObjectFromGUID(guid)
    if obj then
      local silToDestroy = obj.removeAttachments()[1]
      if silToDestroy then silToDestroy.destruct() end
    end
  end
  silhouetteState = false
end"""

# Match the existing `function onload()` body (one-line empty or actual
# code). Idempotent: re-runs detect the marker `MAC PATCH: silhouette reset`
# and skip.
SIL_ONLOAD_RESET_LINE = (
    '    -- MAC PATCH: silhouette reset on load (attachments lost across saves)\n'
    '    silhouetteState = false\n'
)
ONLOAD_OPEN_RE = re.compile(r"function onload\(\)\r?\n")


# SIL button rename (root cause: TTS engine intercepts the click_function
# name "toggleSilhouettes" silently in Mac mode; LCK/R buttons unaffected
# because their click_function names differ. Confirmed empirically 17 mai
# 2026: renaming to "macToggleSil" + forwarder unblocks Mac mode entirely).
#
# We swap the click_function name on the SIL button definition AND inject a
# forwarder function that simply calls toggleSilhouettes(). The original
# toggleSilhouettes is untouched, so Windows mode behavior is identical.
# Idempotent: re-runs detect both markers and skip.
SIL_BUTTON_CLICKFN_OLD = 'click_function = "toggleSilhouettes"'
SIL_BUTTON_CLICKFN_NEW = 'click_function = "macToggleSil"'
SIL_FORWARDER = '''
-- MAC PATCH: rebuilt SIL button click handler. The original click_function
-- name "toggleSilhouettes" is silently intercepted by TTS in Mac mode (the
-- SIL button plays its click sound/animation but the function is never
-- called). Renaming the click_function on the button definition + adding
-- this forwarder restores the routing.
function macToggleSil()
  toggleSilhouettes()
end
-- END MAC PATCH SIL forwarder
'''
SIL_FORWARDER_MARKER = 'function macToggleSil()'


RANGE_WRAPPER = r"""
-- MAC PATCH per-seat router (Range)  -  ALIAS ONLY.
--
-- HISTORY (do not re-introduce): we previously overrode spawnRangeRuler /
-- clearRangeRulers / clearRangeRuler on the ~20 token scripts. That
-- reproducibly SIGSEGV'd TTS Mac (Mono GC_clear_stack_inner) when a fig
-- hotkey spawned the vanilla Range bundle. Overrides REMOVED  -  per-seat
-- Range routing for fig hotkey lives in Global (gRangeTrigger via our
-- initRangebandHotkeys shadow). Tokens' R buttons keep vanilla behavior
-- (magenta on Mac, native on Windows) until a per-token Mac fallback
-- ships  -  see TOKEN_BUTTON_WRAPPER for the per-token override path.
--
-- The single alias below is REQUIRED: Global macModeClick calls
-- obj.call("clearRangeRulersOriginal", obj) on every object holding a
-- rangeRuler state, to wipe the vanilla ruler when toggling modes.
clearRangeRulersOriginal = clearRangeRulers
-- END MAC PATCH per-seat router (Range)
"""

# Order_Token-only overrides: intercept the UI button click handlers
# (toggleCohesionRuler, targetingMode, changeSpeedN, moveX) to capture
# playerColor passed by TTS for per-seat routing.
ORDER_TOKEN_BUTTON_OVERRIDES = r"""
-- MAC PATCH per-seat router (Order_Token button click overrides)
function toggleCohesionRuler(_, playerColor)
    if not rulerOn then
        Global.call("gCohesionTrigger", {
            figGUID     = selectedUnitObj.getGUID(),
            playerColor = playerColor,
        })
        rulerOn = true
    else
        selectedUnitObj.call("clearCohesionRuler")
        rulerOn = false
    end
end

function targetingMode(_, playerColor)
    if not enemyHighlighted then
        exitAttackMode()
        highlightEnemies()
        Global.call("gRangeTrigger", {
            figGUID     = selectedUnitObj.getGUID(),
            playerColor = playerColor,
        })
        enemyHighlighted = true
        resetRangeButtons()
    else
        exitTargetingMode()
    end
end

-- Capture playerColor for Maximum Move per-seat routing. moveUnit() doesn't
-- receive the click color, so each entry-point button stashes it in a
-- script-global var that the spawn block reads. Defaults to nil -> Mac mode.

-- initMove / initDeploy: redefine the body INLINE rather than wrap, because
-- wrapping (capturing the original via a local + calling it) reproducibly
-- broke every Order Token button click in testing (root cause unknown;
-- suspected Lua chunk-level upvalue interaction with TTS engine click
-- dispatch). The inline body mirrors the vanilla logic + the playerColor
-- capture so the MAXMOVE_SPAWN block can route to Mac/Windows per seat.
function initMove(obj, playerColor)
    if not selectedUnitObj then return end
    macActivePlayerForMove = playerColor
    initPos = selectedUnitObj.getPosition()
    initRot = selectedUnitObj.getRotation()
    selectedUnitObj.call("setStartPos")
    moveUnit(false)
end
function initDeploy(obj, playerColor)
    if not selectedUnitObj then return end
    macActivePlayerForMove = playerColor
    initPos = selectedUnitObj.getPosition()
    initRot = selectedUnitObj.getRotation()
    selectedUnitObj.call("setStartPos")
    moveUnit(true)
end

-- INLINE the vanilla bodies (mirror Order_Token.a57c41.lua) rather than
-- wrap. The List Builder copies this block to Command Token Custom_Models
-- which DO NOT carry the vanilla Order_Token function bodies  -  so a
-- wrap-then-call pattern hits `_macOrigChangeSpeed1 = nil` and crashes the
-- moment a Speed/Move button is pressed. Inlining keeps the behavior
-- identical on both Order Tokens (vanilla body re-defined) and Command
-- Tokens (helper fns setTemplateVariables/clearTemplates/moveUnit exist
-- on both because they're part of the include set the List Builder emits).
function changeSpeed1(_, playerColor)
    macActivePlayerForMove = playerColor
    unitData.selectedSpeed = 1
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end
function changeSpeed2(_, playerColor)
    macActivePlayerForMove = playerColor
    unitData.selectedSpeed = 2
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end
function changeSpeed3(_, playerColor)
    macActivePlayerForMove = playerColor
    unitData.selectedSpeed = 3
    setTemplateVariables()
    clearTemplates()
    moveUnit()
end
function moveForward(_, playerColor)
    macActivePlayerForMove = playerColor
    self.editButton({
        index = 11, click_function = "moveBackwards",
        label = "B", tooltip = "Move Backwards"
    })
    moveDirection = "forward"
    moveUnit()
end
function moveBackwards(_, playerColor)
    macActivePlayerForMove = playerColor
    self.editButton({
        index = 11, click_function = "moveForward",
        label = "F", tooltip = "Move Forward"
    })
    moveDirection = "backwards"
    moveUnit()
end
function moveLeft(_, playerColor)
    macActivePlayerForMove = playerColor
    moveDirection = "left"
    moveUnit()
end
function moveRight(_, playerColor)
    macActivePlayerForMove = playerColor
    moveDirection = "right"
    moveUnit()
end
-- END MAC PATCH per-seat router (Order_Token button click overrides)
"""

# Wrapper appended to objects that have `function toggleRangeRuler()`  -
# the R button on tokens (POI, Smoke, Bomb Cart, Objective). Per-seat
# routing: Mac players get our vector bands (TOKEN-spec via rangeKey),
# Windows players get the vanilla token bundle (spawnTokenRangeRuler).
# The vanilla function is aliased BEFORE override so Windows-mode clicks
# can fall through to it.
TOKEN_BUTTON_WRAPPER = r"""
-- MAC PATCH per-seat router (token R button)
-- Aliases the vanilla toggleRangeRuler before overriding so Windows-mode
-- players keep spawning the token-specific Range bundle (POI / Smoke /
-- bomb_cart / objective). Mac-mode players get our vector overlay via
-- gRangeTrigger which dispatches to macBuilders.range with the token's
-- rangeKey var.
local _macToggleRangeRulerOriginal = toggleRangeRuler
function toggleRangeRuler(_, playerColor)
    local mode = Global.call("gGetMode", { color = playerColor })
    if mode == "windows" then
        if _macToggleRangeRulerOriginal then
            return _macToggleRangeRulerOriginal()
        end
        return
    end
    if rangeOn then
        Global.call("gClearRange", { figGUID = self.getGUID() })
        rangeOn = false
    else
        Global.call("gRangeTrigger", {
            figGUID     = self.getGUID(),
            playerColor = playerColor,
        })
        rangeOn = true
    end
end
-- END MAC PATCH per-seat router (token R button)
"""

TOKEN_BUTTON_WRAPPER_RE = re.compile(
    r"\r?\n-- MAC PATCH per-seat router \(token R button\).*?"
    r"-- END MAC PATCH per-seat router \(token R button\)\r?\n",
    re.DOTALL
)

# Idempotent marker  -  used to detect and remove an existing Mac patch in the
# Global LuaScript before applying a fresh one.
GLOBAL_PATCH_MARKER_RE = re.compile(
    r"\r?\n-- ={5,}\r?\n-- MAC COHESION FALLBACK.*?-- END MAC COHESION FALLBACK\r?\n",
    re.DOTALL
)

# Idempotent markers for the per-seat wrappers added to object scripts.
# Strip these before re-applying to avoid double-wrapping.
COHESION_WRAPPER_RE = re.compile(
    r"\r?\n-- MAC PATCH per-seat router \(Cohesion\).*?"
    r"-- END MAC PATCH per-seat router \(Cohesion\)\r?\n",
    re.DOTALL
)
RANGE_WRAPPER_RE = re.compile(
    r"\r?\n-- MAC PATCH per-seat router \(Range\).*?"
    r"-- END MAC PATCH per-seat router \(Range\)\r?\n",
    re.DOTALL
)
ORDER_TOKEN_OVERRIDES_RE = re.compile(
    r"\r?\n-- MAC PATCH per-seat router \(Order_Token button click overrides\).*?"
    r"-- END MAC PATCH per-seat router \(Order_Token button click overrides\)\r?\n",
    re.DOTALL
)


TARGET_GUIDS = {"99f1c8", "a57c41"}  # Objects with the Cohesion block to replace


def collect_patched_scripts(data: dict) -> list:
    """Return script_states for the TTS External Editor API (Save & Play).

    Includes the Global script and any object script we patched (matching
    TARGET_GUIDS). Format: list of dicts with name, guid, script.
    """
    states = [
        {"name": "Global", "guid": "-1", "script": data.get("LuaScript", "")}
    ]

    def walk(o):
        if isinstance(o, dict):
            guid = o.get("GUID", "").lower()
            if guid in TARGET_GUIDS and "LuaScript" in o:
                states.append({
                    "name":   o.get("Name", guid),
                    "guid":   guid,
                    "script": o["LuaScript"],
                })
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for x in o:
                walk(x)

    walk(data)
    return states


def send_to_tts(script_states: list) -> bool:
    """Send a Save & Play (messageID 1) to TTS via the External Editor API.

    Returns True on success, False if TTS isn't listening (likely the API
    is disabled in TTS Configuration).
    """
    msg = {"messageID": 1, "scriptStates": script_states}
    payload = json.dumps(msg).encode("utf-8")
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(3)
        s.connect(("127.0.0.1", 39999))
        s.sendall(payload)
        s.close()
        return True
    except (ConnectionRefusedError, socket.timeout, OSError) as e:
        print(f"  WARN: could not connect to TTS on port 39999 ({e}).")
        print(f"  -> Enable Configuration -> Game Tweaks -> 'External Editor API' in TTS.")
        return False


def patch_object_scripts(data: dict) -> tuple:
    """Walk the JSON tree, replace Cohesion and Range blocks in object scripts.

    Cohesion block: only on TARGET_GUIDS (Unit_Leader, Order_Token).
    Range block: on every object containing the !/RangeRulers include
    (Order_Token, Tokens, POI, bomb_cart, etc.  -  ~20 objects).

    Returns (n_cohesion_patched, n_range_patched, n_dep_patched).
    """
    n_coh, n_rng, n_dep = 0, 0, 0

    def walk(o):
        nonlocal n_coh, n_rng, n_dep
        if isinstance(o, dict):
            guid = o.get("GUID", "").lower()
            if "LuaScript" in o:
                ls = o["LuaScript"]
                changed = False

                # Strip any previous per-seat wrappers so re-runs are idempotent.
                for rx in (COHESION_WRAPPER_RE, RANGE_WRAPPER_RE,
                           ORDER_TOKEN_OVERRIDES_RE, TOKEN_BUTTON_WRAPPER_RE):
                    new_ls, n = rx.subn("", ls)
                    if n > 0:
                        ls = new_ls
                        changed = True

                # Cleanup: strip stale debug prints + repair any signatures
                # mashed by an earlier (overzealous) strip pass. Both are
                # no-ops on a clean save.
                new_ls, n = SIL_DEBUG_STRIP_RE.subn("", ls)
                if n > 0:
                    ls = new_ls
                    changed = True
                for rx in (SIL_REPAIR_TOGGLE_RE, SIL_REPAIR_SHOW_RE, SIL_REPAIR_SPAWN_RE):
                    new_ls, n = rx.subn(r'\1\n\2', ls)
                    if n > 0:
                        ls = new_ls
                        changed = True

                # (Diagnostic SIL prints removed 17 mai 2026 once mute Mac
                # mode confirmed. SIL_DEBUG_STRIP_RE above stays as a cleanup
                # pass for older saves that still carry the prints.)

                # Silhouette URL swap to our Unity-6-compiled bundle.
                # Applies to any object that defines spawnSilhouette
                # (Unit_Leader 99f1c8, Bomb Cart b497e1, POI Token 761483).
                # Idempotent: the regex only matches Steam UGC URLs (/ugc/),
                # not our fork URL, so re-runs are no-ops.
                new_ls, n = SILHOUETTE_URL_RE.subn(SILHOUETTE_URL_REPLACEMENT, ls)
                if n > 0:
                    ls = new_ls
                    changed = True

                # SIL button rename + forwarder. Bypasses the TTS engine
                # bug where the click_function name "toggleSilhouettes" is
                # silently muted in Mac mode. Idempotent: replace() is no-op
                # once swap is done, marker check prevents double-injection.
                if SIL_BUTTON_CLICKFN_OLD in ls:
                    ls = ls.replace(SIL_BUTTON_CLICKFN_OLD, SIL_BUTTON_CLICKFN_NEW)
                    changed = True
                if SIL_BUTTON_CLICKFN_NEW in ls and SIL_FORWARDER_MARKER not in ls:
                    ls = ls.rstrip() + '\n' + SIL_FORWARDER
                    changed = True

                # Cohesion: KEEP the original include block, append per-seat
                # wrapper after it. Only Unit_Leader / Order_Token have it.
                if guid in TARGET_GUIDS:
                    def coh_repl(m):
                        return m.group(0) + COHESION_WRAPPER
                    new_ls, n = COHESION_BLOCK_RE.subn(coh_repl, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        n_coh += 1
                        changed = True

                # Silhouette desync fix (any object with clearSilhouette).
                # Guard the nil-attachment case and reset silhouetteState in
                # onload. Idempotent: the regex matches both the vanilla
                # body and our previously-patched body (same shape).
                if "function clearSilhouette()" in ls:
                    new_ls, n = CLEAR_SILHOUETTE_RE.subn(CLEAR_SILHOUETTE_REPLACEMENT, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        changed = True
                    # Inject the state reset at the top of onload.
                    if "MAC PATCH: silhouette reset on load" not in ls:
                        new_ls, n = ONLOAD_OPEN_RE.subn(
                            "function onload()\n" + SIL_ONLOAD_RESET_LINE,
                            ls, count=1,
                        )
                        if n > 0:
                            ls = new_ls
                            changed = True

                # Range: KEEP block, append wrapper. ~21 objects.
                def rng_repl(m):
                    return m.group(0) + RANGE_WRAPPER
                new_ls, n = RANGE_BLOCK_RE.subn(rng_repl, ls, count=1)
                if n > 0:
                    ls = new_ls
                    n_rng += 1
                    changed = True

                # Maximum Move spawn (only in Order_Token a57c41)  -  Mac only
                if guid == "a57c41":
                    new_ls, n = MAXMOVE_SPAWN_RE.subn(MAXMOVE_SPAWN_REPLACEMENT, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        changed = True
                    new_ls, n = CLEAR_MOVEMENT_RE.subn(CLEAR_MOVEMENT_REPLACEMENT, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        changed = True
                    # Button click overrides (per-seat capture of playerColor)
                    ls = ls + ORDER_TOKEN_BUTTON_OVERRIDES
                    changed = True

                # Token R button: append toggleRangeRuler override on any
                # object that defines that function (POI, Smoke, BombCart,
                # Objective, etc.). Routes the click to the Mac fallback
                # Range overlay sized via TOKEN_BASE_RADIUS. (Already-applied
                # case is handled by the strip loop above.)
                if "function toggleRangeRuler()" in ls:
                    ls = ls + TOKEN_BUTTON_WRAPPER
                    changed = True

                # Deployment Boundary (only in SETUP_CONTROLLER 1cb552)  -  Mac only
                if guid == "1cb552":
                    new_ls, n = DEPLOYMENT_SPAWN_RE.subn(DEPLOYMENT_SPAWN_REPLACEMENT, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        n_dep += 1
                        changed = True
                    new_ls, n = CLEAR_DEPLOYMENT_RE.subn(CLEAR_DEPLOYMENT_REPLACEMENT, ls, count=1)
                    if n > 0:
                        ls = new_ls
                        changed = True

                if changed:
                    o["LuaScript"] = ls

            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for x in o:
                walk(x)

    walk(data)
    return n_coh, n_rng, n_dep


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(args) != 2:
        print(f"Usage: {sys.argv[0]} <input.json> <output.json> [--reload]")
        sys.exit(1)
    src = Path(args[0])
    dst = Path(args[1])
    reload_tts = "--reload" in flags

    with src.open("r") as f:
        data = json.load(f)

    # Rename so the patched save is recognizable in TTS load list.
    data["SaveName"] = "SWL BETA - MAC PATCH"

    # 1. Append manager + handlers to Global LuaScript (idempotent: remove
    # any previous Mac patch block first, then append fresh).
    original_global_len = len(data.get("LuaScript", ""))
    existing = data.get("LuaScript", "")
    cleaned, n_removed = GLOBAL_PATCH_MARKER_RE.subn("", existing)
    data["LuaScript"] = cleaned + GLOBAL_PATCH_LUA
    new_global_len = len(data["LuaScript"])
    note = " (replaced existing patch)" if n_removed else ""
    print(f"Global LuaScript: {original_global_len} -> {new_global_len} bytes{note}")
    print()

    # 2. Replace Cohesion + Range + Deployment blocks in object scripts.
    print("Object script patches:")
    n_coh, n_rng, n_dep = patch_object_scripts(data)
    print(f"  Cohesion blocks replaced:   {n_coh}")
    print(f"  Range blocks replaced:      {n_rng}")
    print(f"  Deployment blocks replaced: {n_dep}")
    print()

    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open("w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Written: {dst}")
    print(f"  Save Name: {data.get('SaveName', '?').strip()}")
    print(f"  Version: {data.get('VersionNumber', '?')}")

    # Mirror to TTS Saves folder so it appears in Games -> Save & Load.
    # Picks the next free TS_Save_N.json slot (TTS scans these on load).
    saves_dir = Path.home() / "Library" / "Tabletop Simulator" / "Saves"
    if saves_dir.exists():
        existing = sorted(
            int(p.stem.split("_")[-1])
            for p in saves_dir.glob("TS_Save_*.json")
            if p.stem.split("_")[-1].isdigit()
        )
        # Reuse the highest existing slot if its content matches the prefix
        # "SWL BETA - MAC PATCH"; else pick next free number.
        target = None
        for n in reversed(existing):
            p = saves_dir / f"TS_Save_{n}.json"
            try:
                with p.open("r") as f:
                    if '"SWL BETA - MAC PATCH"' in f.read(512):
                        target = p
                        break
            except OSError:
                continue
        if target is None:
            next_n = (existing[-1] if existing else 0) + 1
            target = saves_dir / f"TS_Save_{next_n}.json"
        with target.open("w") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  Mirrored to: {target}")

    if reload_tts:
        print()
        print("Hot-reloading into TTS via External Editor API...")
        states = collect_patched_scripts(data)
        print(f"  Sending {len(states)} script(s): "
              + ", ".join(f"{s['name']}({s['guid']})" for s in states))
        if send_to_tts(states):
            print("  OK Sent. TTS should restart Lua with the new code "
                  "(table/objects state preserved).")


if __name__ == "__main__":
    main()
