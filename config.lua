Config = {}

Config.GymPedModel = "a_m_y_clubcust_04"
Config.GymPedCoords = vector4(-1255.53, -354.77, 35.96, 296.64)
Config.GymPassItem = 'gym_pass'
Config.GymPassPrice = 1250

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
        animDict = 'amb@world_human_muscle_free_weights@male@barbell@idle_a',
        anim = 'idle_a',
        prop = 'prop_curl_bar_01',
        label = 'Lift Dumbbells',
        stat = 'strength',
        difficulty = 'medium'
    }
}

-- Chin-ups (Strength)
Config.Chinups = {
    chinup1 = {
        coords = vector3(-1269.8, -362.56, 36.96),
        animDict = 'amb@prop_human_muscle_chin_ups@male@base',
        anim = 'base',
        prop = nil,
        label = 'Do Chin-ups',
        stat = 'strength',
        difficulty = 'hard'
    }
}

-- Bench Press (Strength)
Config.BenchPress = {
    bench1 = {
        coords = vector3(-1200.81, -1563.11, 4.62),
        animDict = 'amb@world_human_muscle_free_weights@male@barbell@base',
        anim = 'base',
        prop = nil,
        label = 'Bench Press',
        stat = 'strength',
        difficulty = 'medium'
    }
}
