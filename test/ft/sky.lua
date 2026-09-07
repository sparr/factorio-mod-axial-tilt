--- The shared ground: nauvis, the mod's settings, and putting both back afterwards.
---
--- Fixtures may write axial-tilt's settings because they are registered from axial-tilt
--- itself -- a mod may only change its own. That is the whole reason this tier can ask
--- what the engine does at latitude -90 without a player touching a settings screen.
local sky = {}

local SETTINGS = {
    latitude = "axial-tilt-latitude",
    tilt = "axial-tilt-axial-tilt",
    days_per_year = "axial-tilt-days-per-year",
    compression = "axial-tilt-time-compression",
}

---@return LuaSurface
function sky.nauvis() return game.surfaces["nauvis"] end

---The settings and daylight as they stand, to be handed back to sky.restore
function sky.snapshot()
    local surface = sky.nauvis()
    local saved = { times = { surface.dusk, surface.evening, surface.morning, surface.dawn },
                    ticks_per_day = surface.ticks_per_day, settings = {} }
    for key, name in pairs(SETTINGS) do saved.settings[key] = settings.global[name].value end
    return saved
end

function sky.restore(saved)
    local surface = sky.nauvis()
    for key, name in pairs(SETTINGS) do settings.global[name] = { value = saved.settings[key] } end
    -- same order the mod uses, for the same reason: the engine will not accept a set of
    -- times that is briefly out of order
    surface.dusk = 0
    surface.evening = .0000000001
    surface.morning = .0000000002
    surface.dawn = saved.times[4]
    surface.morning = saved.times[3]
    surface.evening = saved.times[2]
    surface.dusk = saved.times[1]
    surface.ticks_per_day = saved.ticks_per_day
end

---Point the mod at a place and a date, then let it recalculate
---@param values table latitude, tilt, days_per_year, compression -- any subset
function sky.configure(values)
    for key, value in pairs(values) do
        assert(SETTINGS[key], "no such setting: " .. key)
        settings.global[SETTINGS[key]] = { value = value }
    end
end

return sky
