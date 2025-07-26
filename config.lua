Config = {}

Config.GymPedModel = "a_m_y_clubcust_04"
Config.GymPedCoords = vector4(-1255.53, -354.77, 35.96, 296.64)
Config.GymPassItem = 'gym_pass'
Config.GymPassPrice = 1250
Config.Debug = false

-- Stat Settings
Config.MaxStatLevel = 100
Config.StatIncreaseAmount = 1
Config.WorkoutCooldown = 10 -- seconds between workouts
Config.BonusWorkoutThreshold = 5

-- Stat Degradation Settings
Config.EnableStatDegradation = false -- Enable stat loss over time
Config.DegradationInterval = 3600000 -- 1 hour in milliseconds
Config.StrengthDegradation = 1 -- Points lost per interval
Config.StaminaDegradation = 1 -- Points lost per interval

-- Stat Effects Configuration
Config.StaminaEffects = {
    [10] = { sprintMultiplier = 1.05, staminaRegen = 1.0 },
    [25] = { sprintMultiplier = 1.10, staminaRegen = 1.1 },
    [50] = { sprintMultiplier = 1.20, staminaRegen = 1.2 },
    [75] = { sprintMultiplier = 1.35, staminaRegen = 1.3 },
    [100] = { sprintMultiplier = 1.49, staminaRegen = 1.5 }
}

Config.StrengthEffects = {
    [10] = { meleeDamage = 1.1, punchForce = 1.1 },
    [25] = { meleeDamage = 1.2, punchForce = 1.2 },
    [50] = { meleeDamage = 1.35, punchForce = 1.4 },
    [75] = { meleeDamage = 1.5, punchForce = 1.6 },
    [100] = { meleeDamage = 2.0, punchForce = 2.0 }
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
        chinupCoords = vector3(-1257.00, -358.44, 35.67),
        chinupHeading = 119.6,
        animDict = 'amb@prop_human_muscle_chin_ups@male@base',
        anim = 'base',
        flag = 1,
        prop = nil,
        label = 'Do Chin-ups',
        stat = 'strength',
        difficulty = 'hard',
        duration = 10000,
        barHeight = 38.5, -- Adjust based on your gym's chin-up bar
        animOffset = vector3(0.0, 0.0, 0.0) -- Fine-tune player position during animation
    }
}

-- Bench Press (Strength)
Config.BenchPress = {
    bench1 = {
        coords = vector3(-1262.77, -354.05, 36.96),
        animDict = 'amb@prop_human_seat_muscle_bench_press@idle_a',
        anim = 'idle_a',
        flag = 1,
        prop = 'prop_barbell_20kg',
        equipment = 'prop_weight_bench_02',
        label = 'Bench Press',
        stat = 'strength',
        difficulty = 'medium',
        duration = 8000
    }
}