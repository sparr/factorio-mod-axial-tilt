---A time of day, a number in range `[0, 1)`, with 0 being noon and 0.5 being midnight
---@alias Daytime double

---Round a number to a certain number of decimal places
---@param num number Number to round
---@param dp integer Decimal places
---@return number
function round(num, dp)
  ---@type integer
  local mult = 10^(dp or 0)
  return math.floor(num * mult + 0.5) / mult
end

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
  global.day_num = global.day_num and global.day_num+1 or 1

  ---Number of days per game year
  ---@type integer
  local days_per_year = settings.global['axial-tilt-days-per-year'].value --[[@as integer]]
  ---Axial tilt of the planet in degrees
  ---@type double
  local tilt = settings.global['axial-tilt-axial-tilt'].value --[[@as double]]
  ---Latitude on the planet
  ---@type double
  local latitude = settings.global['axial-tilt-latitude'].value --[[@as double]]
  ---How far into the year is the current date? [0,1)
  ---@type double
  local fraction_of_year = (global.day_num % days_per_year) / days_per_year

  ---Accurate calculation of how long daytime should be as a fraction of the day [0,1)
  ---@type double
  local daytime_fraction = 1/math.pi*math.acos((math.tan(latitude*math.pi/180)*math.sin(tilt*math.pi/180))/math.sqrt(math.tan(fraction_of_year*2*math.pi)*math.tan(fraction_of_year*2*math.pi)+math.cos(fraction_of_year*2*math.pi)*math.cos(fraction_of_year*2*math.pi)))
  if daytime_fraction ~= daytime_fraction then -- NaN
    daytime_fraction = 0
  end
  if fraction_of_year<0.25 or fraction_of_year>0.75 then
    daytime_fraction = 1 - daytime_fraction
  end

  ---hacky calculation of how long dusk and morning should be as a fraction of the non-day time [0,1)
  ---polar winter still has a very short light period
  ---polar spring/summer are lacking some partiadarkness periods
  ---@type double
  local dusk_morning_fraction_of_night = 0.3 + (latitude / 90 * 0.3) - math.abs(0.5 - fraction_of_year) * 0.6

  ---@type Daytime
  local dusk = daytime_fraction / 2.0 - .000000000000002
  ---@type Daytime
  local evening = daytime_fraction / 2.0 + (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 - .000000000000001
  ---@type Daytime
  local morning = 1 - daytime_fraction / 2.0 - (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 + .000000000000001
  ---@type Daytime
  local dawn = 1 - daytime_fraction / 2.0 + .000000000000002

  set_times(game.surfaces["nauvis"], dusk, evening, morning, dawn)
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
