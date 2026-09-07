local seasons = require("lib.seasons")

--- Everything the settings allow. Latitude and tilt are the two the maths is sensitive to.
local TILTS = { 0, 5, 23.4, 45, 66.5, 90 }
local YEARS = { 2, 30, 365 }

describe("fraction_of_year", function()
    it("puts the first day of a thirty day year just past the start", function()
        assert.equals(1 / 30, seasons.fraction_of_year(1, 30))
    end)

    it("wraps at the turn of the year", function()
        assert.equals(0, seasons.fraction_of_year(30, 30))
        assert.equals(1 / 30, seasons.fraction_of_year(31, 30))
    end)

    it("stays inside [0, 1) however many days have passed", function()
        for day = 0, 400 do
            local fraction = seasons.fraction_of_year(day, 30)
            assert.is_true(fraction >= 0 and fraction < 1,
                "day " .. day .. " gave " .. fraction)
        end
    end)
end)

describe("daytime_fraction", function()
    it("splits the day evenly on an untilted planet", function()
        for day = 1, 30 do
            assert.equals(0.5, seasons.daytime_fraction(seasons.fraction_of_year(day, 30), 0, 40))
        end
    end)

    it("gives a longer day in summer than in winter", function()
        -- half a year apart at the same latitude
        local summer = seasons.daytime_fraction(0, 23.4, 40)
        local winter = seasons.daytime_fraction(0.5, 23.4, 40)
        assert.is_true(summer > winter, summer .. " should beat " .. winter)
    end)

    it("keeps a sliver of daylight through a polar winter", function()
        -- with nothing to nudge either side of, dusk would land below zero
        local darkest = seasons.daytime_fraction(0.5, 90, 90)
        assert.equals(seasons.MINIMUM_DAYTIME_FRACTION, darkest)
    end)

    it("never returns less than that sliver, anywhere", function()
        -- one assertion rather than half a million: the loop reports the first day that
        -- breaks and the spec stays quick enough to run on every save
        local worst
        for _, tilt in ipairs(TILTS) do
            for latitude = -90, 90 do
                for _, year in ipairs(YEARS) do
                    for day = 1, year do
                        local fraction = seasons.daytime_fraction(
                            seasons.fraction_of_year(day, year), tilt, latitude)
                        if fraction < seasons.MINIMUM_DAYTIME_FRACTION then
                            worst = worst or ("lat %d tilt %s day %d/%d gave %s")
                                :format(latitude, tilt, day, year, fraction)
                        end
                    end
                end
            end
        end
        assert.is_nil(worst)
    end)

    it("survives the arctangent blowing up at the quarter year", function()
        -- tan goes to infinity a quarter of the way round, and acos of that is NaN
        local fraction = seasons.daytime_fraction(0.25, 23.4, 40)
        assert.equals(fraction, fraction, "NaN escaped the guard")
    end)

    it("mirrors the hemispheres: daylight north and south sums to a whole day", function()
        for _, day in ipairs({ 1, 8, 15, 23 }) do
            local fraction_of_year = seasons.fraction_of_year(day, 30)
            local north = seasons.daytime_fraction(fraction_of_year, 23.4, 40)
            local south = seasons.daytime_fraction(fraction_of_year, 23.4, -40)
            assert.is_true(math.abs(north + south - 1) < 1e-12,
                ("day %d: %s + %s"):format(day, north, south))
        end
    end)
end)

describe("dusk_morning_fraction_of_night", function()
    it("is longest at the poles and shortest at the equator", function()
        local fraction_of_year = 0.5
        assert.is_true(seasons.dusk_morning_fraction_of_night(fraction_of_year, 90)
            > seasons.dusk_morning_fraction_of_night(fraction_of_year, 0))
    end)

    it("reads distance from the equator, not which side of it", function()
        for latitude = 0, 90 do
            for _, day in ipairs({ 1, 8, 15, 23 }) do
                local fraction_of_year = seasons.fraction_of_year(day, 30)
                assert.equals(seasons.dusk_morning_fraction_of_night(fraction_of_year, latitude),
                    seasons.dusk_morning_fraction_of_night(fraction_of_year, -latitude))
            end
        end
    end)

    it("never goes negative, which used to put evening before dusk", function()
        local worst
        for latitude = -90, 90 do
            for _, year in ipairs(YEARS) do
                for day = 1, year do
                    local fraction = seasons.dusk_morning_fraction_of_night(
                        seasons.fraction_of_year(day, year), latitude)
                    if not (fraction >= 0 and fraction <= 1) then
                        worst = worst or ("lat %d day %d/%d gave %s")
                            :format(latitude, day, year, fraction)
                    end
                end
            end
        end
        assert.is_nil(worst)
    end)
end)

describe("times", function()
    it("comes out in the order the engine demands, at the default settings", function()
        for day = 1, 30 do
            local dusk, evening, morning, dawn =
                seasons.times(seasons.fraction_of_year(day, 30), 23.4, 40)
            assert.is_true(dusk < evening and evening < morning and morning < dawn,
                ("day %d: %s %s %s %s"):format(day, dusk, evening, morning, dawn))
        end
    end)

    it("comes out in that order at every latitude, tilt and year length", function()
        -- The whole of the bug 2.1.0 fixed: better than a quarter of this space used to
        -- produce times the engine refuses, killing the mod outright.
        local first_bad, checked = nil, 0
        for _, tilt in ipairs(TILTS) do
            for latitude = -90, 90 do
                for _, year in ipairs(YEARS) do
                    for day = 1, year do
                        local dusk, evening, morning, dawn =
                            seasons.times(seasons.fraction_of_year(day, year), tilt, latitude)
                        checked = checked + 1
                        if not (0 <= dusk and dusk < evening and evening < morning
                                and morning < dawn and dawn < 1) then
                            first_bad = first_bad or
                                ("lat %d tilt %s day %d/%d: %.17g %.17g %.17g %.17g")
                                :format(latitude, tilt, day, year, dusk, evening, morning, dawn)
                        end
                    end
                end
            end
        end
        assert.is_nil(first_bad)
        assert.is_true(checked > 400000, "the sweep stopped covering the settings space")
    end)

    it("is symmetric about noon", function()
        local dusk, evening, morning, dawn = seasons.times(seasons.fraction_of_year(7, 30), 23.4, 40)
        assert.is_true(math.abs((1 - dawn) - dusk) < 1e-12, "dusk and dawn are not mirrored")
        assert.is_true(math.abs((1 - morning) - evening) < 1e-12, "evening and morning are not mirrored")
    end)
end)
