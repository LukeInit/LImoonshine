Config = {}

-- Distillery Placement Settings
Config.Placement = {
    maxDistilleries = 2,           -- Maximum distilleries per player
    minDistanceFromTowns = 500,    -- Minimum distance from towns (meters)
    minDistanceFromRoads = 100,    -- Minimum distance from roads (meters)
    minDistanceBetween = 200,      -- Minimum distance between distilleries (meters)
    requiredItems = {              -- Items needed to place a distillery
        ['distillery_kit'] = 1,
        ['wood'] = 10,
        ['metal'] = 5
    },
    restrictedZones = {            -- Coordinates where distilleries cannot be placed
        -- Add restricted zone coordinates here
        -- {coords = vector3(x, y, z), radius = 100}
    }
}

-- Production Settings
Config.Production = {
    baseTime = 30,                 -- Base production time in minutes
    qualityFactors = {             -- Quality calculation weights
        ingredients = 0.4,
        time = 0.3,
        skill = 0.3
    },
    recipes = {                    -- Available moonshine recipes
        basic = {
            name = "Basic Moonshine",
            ingredients = {
                corn = 5,
                sugar = 3,
                yeast = 1,
                water = 2,
                wood = 3
            },
            time = 30,             -- Production time in minutes
            yield = 3,             -- Number of bottles produced
            quality_base = 50,     -- Base quality score
            difficulty = 1         -- Skill requirement level
        },
        premium = {
            name = "Premium Moonshine",
            ingredients = {
                corn = 8,
                sugar = 5,
                yeast = 2,
                water = 3,
                wood = 5
            },
            time = 45,
            yield = 2,
            quality_base = 75,
            difficulty = 3
        }
    }
}

-- Law Enforcement Settings
Config.LawEnforcement = {
    discoveryChance = 15,          -- Percentage chance per hour of discovery
    raidNotificationTime = 300,    -- Seconds warning before raid
    confiscationRate = 0.8,        -- Percentage of products confiscated
    destructionChance = 0.3,       -- Percentage chance distillery is destroyed
    alertRadius = 1000,            -- Radius for law enforcement alerts
    allowedJobs = {                -- Jobs that can raid distilleries
        'police',
        'sheriff'
    }
}

-- Economy Settings
Config.Economy = {
    sellingLocations = {           -- Where players can sell moonshine
        {
            coords = vector3(-1807.24, -375.94, 160.33), -- Valentine Saloon
            label = "Valentine Saloon",
            npc = "s_m_m_barkeeper_01"
        },
        {
            coords = vector3(2796.84, -1167.59, 47.93),   -- Saint Denis Saloon
            label = "Saint Denis Saloon", 
            npc = "s_m_m_barkeeper_01"
        }
    },
    basePrice = 15,                -- Base price per bottle
    qualityMultiplier = 1.5,       -- Price multiplier for high quality
    lawEnforcementRisk = 25        -- Percentage chance of attracting attention when selling
}

-- Distillery Object Settings
Config.Objects = {
    distilleryModel = `p_still02x`,    -- Distillery object model hash
    interactionDistance = 3.0,         -- Distance for interaction prompts
    promptKey = 0xE30CD707             -- Interaction key (R key)
}

-- Notification Settings
Config.Notifications = {
    productionComplete = true,      -- Notify when production is complete
    raidWarning = true,            -- Notify when raid is incoming
    discoveryAlert = true          -- Notify when distillery is discovered
}