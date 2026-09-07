--- The arithmetic behind the seasons, with no game attached: where in the year a day
--- falls, how much of that day is lit, and the four times the engine wants for it.
--- Everything that touches a surface stays in control.lua, so these can be tested without
--- a game.
local seasons = {}

---The least daylight a day may have. The four transition times are derived by nudging a
---few femtoseconds either side of the daylight period, so with no daylight at all -- a
---polar midwinter -- dusk lands a nudge below zero and dawn a nudge past one, outside the
---day they are meant to describe.
---
---The engine does not object: measured against 2.1.17, it checks only that the four stay
---strictly ordered, and stores anything else you hand it verbatim. This keeps them inside
---the day regardless. It is not what stops the mod crashing -- that is
---dusk_morning_fraction_of_night reading distance from the equator.
---@type number
seasons.MINIMUM_DAYTIME_FRACTION = 1e-12

---How far into the year a day falls, in [0, 1)
---@param day_num integer
---@param days_per_year integer
---@return number
function seasons.fraction_of_year(day_num, days_per_year)
  return (day_num % days_per_year) / days_per_year
end

---How much of the day is lit, as a fraction in (0, 1]
---@param fraction_of_year number
---@param tilt number Axial tilt of the planet, in degrees
---@param latitude number Latitude on the planet, in degrees
---@return number
function seasons.daytime_fraction(fraction_of_year, tilt, latitude)
  local fraction = 1/math.pi*math.acos((math.tan(latitude*math.pi/180)*math.sin(tilt*math.pi/180))/math.sqrt(math.tan(fraction_of_year*2*math.pi)*math.tan(fraction_of_year*2*math.pi)+math.cos(fraction_of_year*2*math.pi)*math.cos(fraction_of_year*2*math.pi)))
  if fraction ~= fraction then -- NaN
    fraction = 0
  end
  if fraction_of_year<0.25 or fraction_of_year>0.75 then
    fraction = 1 - fraction
  end
  if fraction < seasons.MINIMUM_DAYTIME_FRACTION then
    fraction = seasons.MINIMUM_DAYTIME_FRACTION
  end
  return fraction
end

---Hacky calculation of how long dusk and morning should be as a fraction of the non-day
---time [0,1). Polar winter still has a very short light period; polar spring and summer
---are lacking some partial darkness periods.
---
---It reads distance from the equator, not signed latitude: what lengthens dawn and dusk
---is how far from the equator you are, and signed latitude shortened them going south
---instead, past zero into negative, which put evening before dusk.
---@param fraction_of_year number
---@param latitude number
---@return number
function seasons.dusk_morning_fraction_of_night(fraction_of_year, latitude)
  local distance_from_equator = math.abs(latitude)
  return 0.3 + (distance_from_equator / 90 * 0.3) - math.abs(0.5 - fraction_of_year) * 0.6
end

---The four daylight transition times for a day, always satisfying
---`0 <= dusk < evening < morning < dawn < 1`, which is what the engine will accept.
---@param fraction_of_year number
---@param tilt number
---@param latitude number
---@return number dusk, number evening, number morning, number dawn
function seasons.times(fraction_of_year, tilt, latitude)
  local daytime_fraction = seasons.daytime_fraction(fraction_of_year, tilt, latitude)
  local dusk_morning_fraction_of_night =
    seasons.dusk_morning_fraction_of_night(fraction_of_year, latitude)

  local dusk = daytime_fraction / 2.0 - .000000000000002
  local evening = daytime_fraction / 2.0 + (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 - .000000000000001
  local morning = 1 - daytime_fraction / 2.0 - (dusk_morning_fraction_of_night * (1 - daytime_fraction)) / 2.0 + .000000000000001
  local dawn = 1 - daytime_fraction / 2.0 + .000000000000002
  return dusk, evening, morning, dawn
end

return seasons
