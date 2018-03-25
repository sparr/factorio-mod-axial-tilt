# Axial Tilt
A mod for the game Factorio, adding seasonal changes to the length of the day.

The base game has the day split into 50% daytime, 40% dawn/dusk, 10% night.
The default settings for this mod alter that on a 30-day cycle, with the shortest
daytime being 20% and the longest 70%. Winter has long nights and summer has dusk
transitioning to dawn with no full darkness at all.

The dawn/dusk transitions are also adjusted from linear to sine curves.

The mod exposes settings for the minimum and maximum daytime length, as well as
the number of days per year.

* day length 25000 is permanent daytime.
* day length >= 15000 has no full night, just some dusk/dawn.
* day length 12500 matches the base game.
* day length <=0 has no full sunlight, just some dawn/dusk.
* day length -10000 is permanent darkness.

There is a known bug with day length <=0; the shorter the year the sharper the
transitions at noon will be between consecutive days' maximum amount of light.