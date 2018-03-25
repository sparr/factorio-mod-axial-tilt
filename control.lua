-- local function debug(...)
--   if game and game.players[1] then
--     game.players[1].print("DEBUG: " .. serpent.line(...,{comment=false}))
--   end
-- end

local min_day_length = settings.global['axial-tilt-min-day-length'].value
local max_day_length = settings.global['axial-tilt-max-day-length'].value
local days_per_year  = settings.global['axial-tilt-days-per-year' ].value

local seasonal_variance = max_day_length - min_day_length

local day_length, day_end, night_start, night_end, day_start, night_length

local ticks_per_day = 25000
local dusk_dawn_length = 5000

local function on_tick(event)
  local tick_in_day = event.tick % ticks_per_day
  -- once per game day
  if tick_in_day == 0 or day_length == nil then
    -- update daytime modifiers for today
    local day = event.tick / ticks_per_day
    local day_of_year = day % days_per_year + 0.5
    local percent_of_year = day_of_year / days_per_year
    local angle_in_year = percent_of_year * math.pi * 2.0
    local start_angle = 0 -- spring equinox
    -- day length 12500 is default, day is 50% sun, 40% dawn/dusk, 10% night
    -- day length 25000 means permanent sunlight
    -- day length >=15000 means no full night, dusk transitions to dawn
    -- day length <=0 means no full sunlight, dawn transitions to dusk
    -- day length -10000 means permanent night
    day_length = seasonal_variance * (math.sin(angle_in_year + start_angle) + 1) / 2.0 + min_day_length
    night_length = ticks_per_day - day_length - dusk_dawn_length * 2.0
    day_end = day_length / 2.0
    night_start = day_end + dusk_dawn_length
    day_start = ticks_per_day - day_length / 2.0
    night_end = day_start - dusk_dawn_length
    -- debug("day " .. day .. " " .. day_of_year .. "/" .. days_per_year .. " day length " .. day_length)
  end

  -- 10 updates per second
  if event.tick % 6 == 2 then
    -- update daytime on main surface
    -- surface.daytime reference:
    -- 0.00 noon
    -- 0.25 sunset
    -- 0.45 dark
    -- 0.50 midnight
    -- 0.55 end of dark
    -- 0.75 sunrise

    --FIXME sharp transition at noon when day_length<0
    local daytime = 0
    if tick_in_day < day_end then
      -- afternoon
      daytime = tick_in_day / day_end * 0.25
    elseif tick_in_day > day_start then
      -- morning
      daytime = (tick_in_day - day_start) / (ticks_per_day - day_start) * 0.25 + 0.75
    elseif tick_in_day < night_start and tick_in_day < ticks_per_day / 2 then
      -- dusk
      -- sin curve gives smoother transition than stock linear gradient
      daytime = (math.sin((tick_in_day - day_end  ) / dusk_dawn_length * math.pi - math.pi/2.0) / 2.0 + 0.5) * 0.20 + 0.25
    elseif tick_in_day > night_end then
      -- dawn
      daytime = (math.sin((tick_in_day - night_end) / dusk_dawn_length * math.pi - math.pi/2.0) / 2.0 + 0.5) * 0.20 + 0.55
    else
      -- night
      daytime = (tick_in_day - night_start) / night_length * 0.10 + 0.45
    end
    -- if event.tick % 300 == 2 then
    --   debug("tick " .. tick_in_day .. " daytime " .. daytime)
    -- end
    game.surfaces["nauvis"].daytime = daytime
  end
end

script.on_event(defines.events.on_tick, on_tick)