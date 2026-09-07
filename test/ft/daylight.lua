--- What the engine actually does with the times the maths produces.
---
--- The unit tier knows the ordering rule only from a comment in the source. This tier
--- puts the numbers on a real surface and finds out whether the engine agrees.
local seasons = require("lib.seasons")
local sky = require("test.ft.sky")

local saved
before_each(function() saved = sky.snapshot() end)
after_each(function() sky.restore(saved) end)

describe("what the engine actually enforces", function()
    -- The unit tier knows the rule only from a comment. These four are where the rule
    -- comes from, and they are the reason set_times does its odd reset dance.
    test("refuses times that are not strictly ordered", function()
        local surface = sky.nauvis()
        assert.is_false(pcall(function() surface.dawn = surface.morning - 0.1 end),
            "the engine accepted dawn before morning")
        assert.is_false(pcall(function() surface.evening = surface.dusk end),
            "the engine accepted evening equal to dusk, so the rule is not strict")
    end)

    test("accepts times outside the day entirely, so range is not the constraint", function()
        -- worth pinning: it would be easy to assume [0, 1) is enforced, and to add a
        -- clamp believing it prevents a crash. It does not.
        local surface = sky.nauvis()
        assert.is_true(pcall(function() surface.dusk = -0.001 end),
            "the engine now refuses a negative dusk; the clamp has become load-bearing")
        assert.equals(-0.001, surface.dusk, "a negative dusk did not survive the round trip")
        assert.is_true(pcall(function() surface.dawn = 1.5 end),
            "the engine now refuses a dawn past one")
        assert.equals(1.5, surface.dawn, "a dawn past one did not survive the round trip")
    end)

    test("measures each assignment against whatever is already set", function()
        -- which is why set_times parks the placeholders at 0, 1e-10 and 2e-10 first: every
        -- one of the four has to clear them on the way to its real value
        local surface = sky.nauvis()
        surface.dusk = 0
        surface.evening = .0000000001
        surface.morning = .0000000002
        assert.is_false(pcall(function() surface.evening = -1e-15 end),
            "an evening below the placeholder dusk was accepted")
    end)
end)

describe("the times the mod produces", function()
    test("are accepted at the default settings, right round the year", function()
        local surface = sky.nauvis()
        for day = 1, 30 do
            local ok, err = pcall(set_times, surface,
                seasons.times(seasons.fraction_of_year(day, 30), 23.4, 40))
            assert.is_true(ok, ("day %d of the default year: %s"):format(day, tostring(err)))
        end
    end)

    test("are accepted at every latitude, which is what 2.1.0 fixed", function()
        -- Better than a quarter of this space used to be refused outright, and the refusal
        -- kills the mod rather than being caught. -40 alone was fatal on world creation.
        local surface = sky.nauvis()
        local refused
        for latitude = -90, 90, 5 do
            for _, tilt in ipairs({ 0, 23.4, 66.5, 90 }) do
                for day = 1, 30 do
                    local ok, err = pcall(set_times, surface,
                        seasons.times(seasons.fraction_of_year(day, 30), tilt, latitude))
                    if not ok then
                        refused = refused or ("lat %d tilt %s day %d: %s")
                            :format(latitude, tilt, day, tostring(err))
                    end
                end
            end
        end
        assert.is_nil(refused)
    end)
end)

describe("the mod applied to nauvis", function()
    test("puts its own times on the surface", function()
        sky.configure({ latitude = 40, tilt = 23.4, days_per_year = 30 })
        update_durations()

        local surface = sky.nauvis()
        local expected_dusk = seasons.times(
            seasons.fraction_of_year(storage.day_num, 30), 23.4, 40)
        assert.is_true(math.abs(surface.dusk - expected_dusk) < 1e-9,
            ("surface has dusk %.9f, the maths asked for %.9f"):format(surface.dusk, expected_dusk))
    end)

    test("advances the day by one each time it recalculates", function()
        local before = storage.day_num
        update_durations()
        assert.equals(before + 1, storage.day_num)
    end)

    test("survives a whole year south of the equator", function()
        -- latitude -40 used to die in on_init, before the world existed
        sky.configure({ latitude = -40, tilt = 23.4, days_per_year = 30 })
        for _ = 1, 30 do
            local ok, err = pcall(update_durations)
            assert.is_true(ok, "day " .. tostring(storage.day_num) .. ": " .. tostring(err))
        end
    end)

    test("survives a whole year at the pole", function()
        sky.configure({ latitude = -90, tilt = 66.5, days_per_year = 30 })
        for _ = 1, 30 do
            local ok, err = pcall(update_durations)
            assert.is_true(ok, "day " .. tostring(storage.day_num) .. ": " .. tostring(err))
        end
    end)
end)

describe("the time compression setting", function()
    test("stretches and shrinks the day", function()
        local surface = sky.nauvis()
        sky.configure({ compression = 1 })
        surface.ticks_per_day = 1 / settings.global["axial-tilt-time-compression"].value * 25000
        assert.equals(25000, surface.ticks_per_day)

        sky.configure({ compression = 100 })
        surface.ticks_per_day = 1 / settings.global["axial-tilt-time-compression"].value * 25000
        assert.equals(250, surface.ticks_per_day)
    end)
end)
