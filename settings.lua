data:extend(
  {
    {
      type = "double-setting",
      name = "axial-tilt-time-compression",
      setting_type = "runtime-global",
      default_value = 1,
      minimum_value = 0.0001,
      maximum_value = 100
    },
    {
      type = "int-setting",
      name = "axial-tilt-days-per-year",
      setting_type = "runtime-global",
      default_value = 30,
      minimum_value = 2,
      maximum_value = 10000
    },
    {
      type = "double-setting",
      name = "axial-tilt-axial-tilt",
      setting_type = "runtime-global",
      default_value = 23.4,
      minimum_value = 0,
      maximum_value = 90
    },
    {
      type = "double-setting",
      name = "axial-tilt-latitude",
      setting_type = "runtime-global",
      default_value = 40,
      minimum_value = -90,
      maximum_value = 90
    },
  } --[=[@as data.AnyModSetting[]]=]
)