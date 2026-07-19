Config = {}

Config.EmsJobs = {
    ambulance = true,
    fire = true,
}

Config.MinimalDoctors = 2
Config.WipeInventoryOnRespawn = true
Config.BillCost = 2000
Config.DeathTime = 300          -- seconds until forced respawn
Config.LaststandTime = 180      -- seconds in laststand before death
Config.ReviveInterval = 15      -- progress bar seconds for revive
Config.HealInterval = 8
Config.CheckInTime = 20         -- AI heal seconds
Config.Helicopter = 'polmav'
Config.BleedTickRate = 30
Config.BleedTickDamage = 6

Config.Items = {
    firstaid = 'firstaid',
    bandage = 'bandage',
    painkillers = 'painkillers',
}

-- Soft integrations
Config.UsePsDispatch = true
Config.UsePsMdt = true

Config.AuthorizedVehicles = {
    [0] = {
        { model = 'ambulance', label = 'Ambulance' },
    },
}

Config.Locations = {
    checking = {
        vector3(308.19, -595.35, 43.29),
        vector3(-254.54, 6331.78, 32.43),
    },
    duty = {
        vector3(311.18, -599.25, 43.29),
        vector3(-254.88, 6324.5, 32.58),
    },
    vehicle = {
        vector4(294.578, -574.761, 43.179, 35.79),
        vector4(-234.28, 6329.16, 32.15, 222.5),
    },
    helicopter = {
        vector4(351.58, -587.45, 74.16, 160.5),
        vector4(-475.43, 5988.353, 31.716, 31.34),
    },
    roof = {
        vector4(338.5, -583.85, 74.16, 245.5),
    },
    main = {
        vector3(298.74, -599.33, 43.29),
    },
    stash = {
        vector3(309.78, -596.6, 43.29),
    },
    beds = {
        { coords = vector4(353.1, -584.6, 43.11, 152.08), model = 1631638868 },
        { coords = vector4(356.79, -585.86, 43.11, 152.08), model = 1631638868 },
        { coords = vector4(354.12, -593.12, 43.1, 336.32), model = 2117668672 },
        { coords = vector4(350.79, -591.8, 43.1, 336.32), model = 2117668672 },
        { coords = vector4(346.99, -590.48, 43.1, 336.32), model = 2117668672 },
        { coords = vector4(360.32, -587.19, 43.02, 152.08), model = -1091386327 },
        { coords = vector4(349.82, -583.33, 43.02, 152.08), model = -1091386327 },
        { coords = vector4(326.98, -576.17, 43.02, 152.08), model = -1091386327 },
        { coords = vector4(-252.43, 6312.25, 32.34, 313.48), model = 2117668672 },
        { coords = vector4(-247.04, 6317.95, 32.34, 134.64), model = 2117668672 },
        { coords = vector4(-255.98, 6315.67, 32.34, 313.91), model = 2117668672 },
    },
    hospitals = {
        { name = 'Pillbox Hospital', location = vector3(308.36, -595.25, 43.28) },
        { name = 'Paleto Hospital', location = vector3(-254.54, 6331.78, 32.43) },
    },
    stations = {
        { label = 'Pillbox EMS', coords = vector3(304.27, -600.33, 43.28), sprite = 61, color = 1 },
    },
}
