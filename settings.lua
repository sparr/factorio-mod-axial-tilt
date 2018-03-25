data:extend(
  {
    -- -- compound spherical trig is hard
    -- {
    --   type = "double-setting",
    --   name = "axial-tilt-tilt",
    --   setting_type = "runtime-global",
    --   per_user = "false",
    --   admin = "true",
    --   default_value = 23,
    --   minimum_value = 0,
    --   maximum_value = 90
    -- },
    -- {
    --   type = "double-setting",
    --   name = "axial-tilt-latitude",
    --   setting_type = "runtime-global",
    --   per_user = "false",
    --   admin = "true",
    --   default_value = 40
    --   minimum_value = -90
    --   maximum_value = 90
    -- },
    {
      type = "int-setting",
      name = "axial-tilt-min-day-length",
      setting_type = "runtime-global",
      per_user = "false",
      admin = "true",
      default_value = 5000,
      minimum_value = -10000,
      maximum_value = 25000,
    },
    {
      type = "int-setting",
      name = "axial-tilt-max-day-length",
      setting_type = "runtime-global",
      per_user = "false",
      admin = "true",
      default_value = 17500,
      minimum_value = -10000,
      maximum_value = 25000,
    },
    {
      type = "int-setting",
      name = "axial-tilt-days-per-year",
      setting_type = "runtime-global",
      per_user = "false",
      admin = "true",
      default_value = 30,
      minimum_value = 2,
    },
  }
)
