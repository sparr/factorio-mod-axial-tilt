# The integration tier

10 tests that ask a real Factorio what it actually does, on top of
[factorio-test](https://mods.factorio.com/mod/factorio-test). Headless, no display, a
couple of seconds end to end.

```bash
npm install                    # once: fetches factorio-test-cli
test/ft/run.sh                 # the whole suite
test/ft/run.sh -v              # with the game's own log lines
test/ft/run.sh "pole"          # only tests matching a Lua pattern
test/ft/run.sh -b              # stop at the first failure
```

`AT_FACTORIO` points at the game binary, `AT_FT_DATA` at the throwaway data directory the
run happens in (`~/.cache/axial-tilt-factorio-test` by default, deliberately outside the
repo — the runner symlinks the mod under test into that directory's mods folder, so a data
directory inside the repo would make the repo contain itself). Two runs cannot share one
data directory.

The unit tier is separate: `test/run.sh` runs the busted specs in `test/spec` against
`lib/`, in half a second, with no game at all. Pure arithmetic belongs there. Anything
about what the engine really does belongs here. Both tiers assert with luassert, so
`assert.equals` and friends mean the same thing on either side of the line.

## How it fits together

- `control.lua` registers the fixtures, guarded on both `factorio-test` and `at-tests`
  being loaded. `at-tests` is never published, so the hook can never fire on a player's
  machine — which matters, because `info.json` keeps `test/` out of the package and the
  fixtures would not be there to require.
- Registering from *this* mod rather than from `at-tests` is what lets a fixture write
  `axial-tilt-latitude`: a mod may only change its own settings, and these tests are the
  owning mod. That is the whole reason this tier can ask what happens at latitude −90
  without anyone touching a settings screen.
- `test/ft/at-tests` holds no prototypes. It exists solely as the marker that says "this
  is a test run", so the hook above has something to check.
- `test/ft/sky.lua` snapshots the four times, `ticks_per_day` and every setting before
  each test and puts them back after, so a fixture that moves the planet to the pole does
  not leave it there.

## What the engine actually enforces

Three of the ten exist because assuming was wrong. The engine checks that
`dusk < evening < morning < dawn`, strictly, and **nothing else** — hand it a dusk of
−0.001 or a dawn of 1.5 and it stores them verbatim and reads them back unchanged. There
is no [0, 1) range check.

That is why `set_times` parks placeholders at 0, 1e-10 and 2e-10 before writing the real
values: each assignment is measured against whatever is currently set, so all four have to
clear the placeholders on the way past. It is also why `MINIMUM_DAYTIME_FRACTION` is a
tidiness measure rather than a crash fix — the fixture that pins it says so, and will fail
loudly if a future version starts enforcing a range and makes it load-bearing.
