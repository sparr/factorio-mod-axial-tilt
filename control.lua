-- local function debug(...)
--   if game and game.players[1] then
--     game.players[1].print("DEBUG: " .. serpent.line(...,{comment=false}))
--   end
-- end

-- function round(num, numDecimalPlaces)
--   local mult = 10^(numDecimalPlaces or 0)
--   return math.floor(num * mult + 0.5) / mult
-- end

local function on_init()
  game.surfaces["nauvis"].ticks_per_day = 1 / settings.global['axial-tilt-time-compression'].value * 25000
  update_durations()
end

local function on_configuration_changed()
  game.surfaces["nauvis"].ticks_per_day = 1 / settings.global['axial-tilt-time-compression'].value * 25000
end

-- a hack to avoid range errors when changing multiple times at once
function set_times(surface, dusk, evening, morning, dawn)
  surface.dusk = 0
  surface.evening = .0000000001
  surface.morning = .0000000002
  surface.dawn = dawn
  surface.morning = morning
  surface.evening = evening
  surface.dusk = dusk
end

function update_durations()
  global.day_num = global.day_num and global.day_num+1 or 1
  -- update daytime modifiers for today
  local days_per_year = settings.global['axial-tilt-days-per-year'].value
  local tilt = settings.global['axial-tilt-axial-tilt'].value
  local latitude = settings.global['axial-tilt-latitude'].value
  local fraction_of_year = (global.day_num % days_per_year) / days_per_year
  -- entirely accurate calculation of how long daytime should be
  local daytime_fraction = 1/math.pi*math.acos((math.tan(latitude*math.pi/180)*math.sin(tilt*math.pi/180))/math.sqrt(math.tan(fraction_of_year*2*math.pi)*math.tan(fraction_of_year*2*math.pi)+math.cos(fraction_of_year*2*math.pi)*math.cos(fraction_of_year*2*math.pi)))
  if daytime_fraction ~= daytime_fraction then -- NaN
    daytime_fraction = 0
  end
  if fraction_of_year<0.25 or fraction_of_year>0.75 then
    daytime_fraction = 1 - daytime_fraction
  end
  -- completely hacky calculation of how long dusk and morning should be
  -- polar winter still has a very short light period
  -- polar spring/summer are lacking some partial darkness periods
  dusk_morning_fraction_of_night = 0.3 + (latitude / 90 * 0.3) - (fraction_of_year % 0.5 * 0.6)
  local dusk = daytime_fraction / 2.0 - .000000000000002
  local evening = daytime_fraction / 2.0 + (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 - .000000000000001
  local morning = 1 - daytime_fraction / 2.0 - (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 + .000000000000001
  local dawn = 1 - daytime_fraction / 2.0 + .000000000000002
  set_times(game.surfaces["nauvis"], dusk, evening, morning, dawn)
  -- debug("day " .. global.day_num .. "/" .. days_per_year .. "=" .. round(fraction_of_year,6) .. ", day:" .. round(daytime_fraction,6) .. " duskmorn:" .. round(dusk_morning_fraction_of_night,6))
end

-- TODO: replace with registered Nth tick handler that is aware of configuration changes?
local function on_tick(event)
  -- once per game day, at noon(ish)
  if (not game.surfaces["nauvis"].always_day) and game.surfaces["nauvis"].daytime < 1/game.surfaces["nauvis"].ticks_per_day then
    update_durations()
  end
end

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_tick, on_tick)
