-- 2.0 renamed the table a mod's state lives in from `global` to `storage`.

local seasons = require("lib.seasons")

---A time of day, a number in range `[0, 1)`, with 0 being noon and 0.5 being midnight
---@alias Daytime number

local function setup()
  game.surfaces["nauvis"].ticks_per_day = 1 / settings.global['axial-tilt-time-compression'].value * 25000
  update_durations()
end

---Set all daylight transition times for a surface
---@param surface LuaSurface
---@param dusk Daytime When dusk (fade from light to dark) starts
---@param evening Daytime When evening (dark night time) starts
---@param morning Daytime When morning (light day time) starts
---@param dawn Daytime When dawn (fade from dark to light) starts
function set_times(surface, dusk, evening, morning, dawn)
  -- Any attempt to set times that don't fit dusk<evening<morning<dawn is an error condition,
  -- so we temporarily set the lowest possible valid times, then set them to the target values
  surface.dusk = 0
  surface.evening = .0000000001
  surface.morning = .0000000002
  surface.dawn = dawn
  surface.morning = morning
  surface.evening = evening
  surface.dusk = dusk
end

---Calculate and apply the light/dark transition times based on settings and the in-game date
function update_durations()
  ---Counter for the in-game date
  ---@type integer
  storage.day_num = storage.day_num and storage.day_num+1 or 1

  ---Number of days per game year
  ---@type integer
  local days_per_year = settings.global['axial-tilt-days-per-year'].value --[[@as integer]]
  ---Axial tilt of the planet in degrees
  ---@type double
  local tilt = settings.global['axial-tilt-axial-tilt'].value --[[@as double]]
  ---Latitude on the planet
  ---@type double
  local latitude = settings.global['axial-tilt-latitude'].value --[[@as double]]

  local fraction_of_year = seasons.fraction_of_year(storage.day_num, days_per_year)
  set_times(game.surfaces["nauvis"], seasons.times(fraction_of_year, tilt, latitude))
end

---@param _ EventData.on_tick
local function on_tick(_)
  -- once per game day, at noon(ish) to avoid discontinuities where possible
  if (not game.surfaces["nauvis"].always_day) and game.surfaces["nauvis"].daytime < 1/game.surfaces["nauvis"].ticks_per_day then
    update_durations()
  end
end

script.on_init(setup)
script.on_configuration_changed(setup)

-- TODO: replace with registered Nth tick handler that is aware of configuration changes?
script.on_event(defines.events.on_tick, on_tick)
