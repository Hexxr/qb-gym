Config = {}

Config.GymPedModel = "a_m_y_clubcust_04"
Config.GymPedCoords = vector4(-1255.53, -354.77, 35.96, 296.64)
Config.GymPassItem = 'gym_pass'
Config.GymPassPrice = 1250

-- Stat Settings
Config.MaxStatLevel = 100
Config.StatIncreaseAmount = 1
Config.WorkoutCooldown = 30 -- seconds between workouts

-- Stat Effects Configuration
Config.StaminaEffects = {
    [10] = { sprintMultiplier = 1.05 },
    [25] = { sprintMultiplier = 1.10 },
    [50] = { sprintMultiplier = 1.20 },
    [75] = { sprintMultiplier = 1.35 },
    [100] = { sprintMultiplier = 1.49 }
}

Config.StrengthEffects = {
    [10] = { meleeDamage = 1.1 },
    [25] = { meleeDamage = 1.2 },
    [50] = { meleeDamage = 1.35 },
    [75] = { meleeDamage = 1.5 },
    [100] = { meleeDamage = 2.0 }
}

-- Treadmills (Stamina)
Config.Treadmills = {
    treadmill1 = {
        coords = vector3(-1257.71, -366.51, 35.72), -- Interaction point
        treadmillCoords = vector3(-1257.79, -366.25, 35.80), -- Where player stands on treadmill
        treadmillHeading = 213.31, -- Direction to face
        animDict = 'amb@world_human_jog_standing@male@base',
        anim = 'base',
        flag = 1, -- Loop animation
        prop = nil,
        label = 'Use Treadmill',
        stat = 'stamina',
        difficulty = 'easy',
        duration = 15000 -- 15 seconds of running
    },
}

-- Dumbbells (Strength)
Config.Dumbbells = {
    dumbbell1 = {
        coords = vector3(-1268.11, -366.05, 36.99),
        animDict = 'amb@world_human_muscle_free_weights@male@barbell@base',
        anim = 'base',
        flag = 1,
        prop = 'prop_curl_bar_01',
        label = 'Lift Dumbbells',
        stat = 'strength',
        difficulty = 'medium',
        duration = 8000
    },
}

-- Chin-ups (Strength)
Config.Chinups = {
    chinup1 = {
        coords = vector3(-1256.68, -359.83, 36.96),
        chinupCoords = vector3(-1256.91, -358.43, 35.64),
        chinupHeading = 295.7,
        animDict = 'amb@prop_human_muscle_chin_ups@male@base',
        anim = 'base',
        flag = 1,
        prop = nil,
        label = 'Do Chin-ups',
        stat = 'strength',
        difficulty = 'hard',
        duration = 10000
    }
}

-- Bench Press (Strength)
Config.BenchPress = {
    bench1 = {
        coords = vector3(-1262.77, -354.05, 36.96),
        animDict = 'amb@world_human_muscle_free_weights@male@barbell@base',
        anim = 'base',
        flag = 1,
        prop = nil,
        label = 'Bench Press',
        stat = 'strength',
        difficulty = 'medium',
        duration = 8000
    }
}
