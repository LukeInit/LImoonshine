# LIMOONSHINE - Moonshine Distillery System for RedM

A comprehensive moonshine distillery system for QBCore RedM servers that allows players to place distilleries, produce moonshine, and engage in illegal activities while avoiding law enforcement.

## Features

### Core Gameplay
- **Distillery Placement**: Players can place distilleries in remote locations using a distillery kit
- **Moonshine Production**: Multiple recipes with different ingredients, production times, and quality levels
- **Quality System**: Moonshine quality affects selling price and is based on ingredients and production conditions
- **Law Enforcement Raids**: Police and sheriffs can discover and raid distilleries
- **Economy Integration**: Sell moonshine at various locations with risk/reward mechanics

### Advanced Features
- **Distance Restrictions**: Distilleries must be placed away from towns, roads, and other distilleries
- **Production Timers**: Realistic production times with server-side validation
- **Discovery System**: Law enforcement can randomly discover distilleries
- **Raid Mechanics**: Confiscation of products and potential distillery destruction
- **Administrative Tools**: Commands for server management and cleanup

## Installation

1. Place the `LIMOONSHINE` folder in your `resources/[standalone]/` directory
2. Add `ensure LIMOONSHINE` to your server.cfg
3. Add the required items to your QBCore items database:

```sql
INSERT INTO `items` (`name`, `label`, `weight`, `type`, `image`, `unique`, `useable`, `shouldClose`, `combinable`, `description`) VALUES
('distillery_kit', 'Distillery Kit', 10, 'item', 'distillery_kit.png', 0, 1, 1, 0, 'Everything needed to set up a moonshine distillery'),
('moonshine', 'Moonshine', 1, 'item', 'moonshine.png', 0, 1, 1, 0, 'Homemade moonshine whiskey'),
('corn', 'Corn', 1, 'item', 'corn.png', 0, 0, 1, 0, 'Fresh corn for moonshine production'),
('sugar', 'Sugar', 1, 'item', 'sugar.png', 0, 0, 1, 0, 'Sugar for fermentation'),
('yeast', 'Yeast', 1, 'item', 'yeast.png', 0, 0, 1, 0, 'Yeast for fermentation'),
('water', 'Water', 1, 'item', 'water.png', 0, 0, 1, 0, 'Clean water'),
('wood', 'Wood', 1, 'item', 'wood.png', 0, 0, 1, 0, 'Wood for fuel and construction'),
('metal', 'Metal', 1, 'item', 'metal.png', 0, 0, 1, 0, 'Metal for construction');
```

## Usage

### For Players
1. **Placing a Distillery**: Use a distillery kit in a remote location away from towns and roads
2. **Starting Production**: Interact with your distillery and select a recipe (requires ingredients)
3. **Collecting Moonshine**: Return when production is complete to collect your moonshine
4. **Selling Moonshine**: Visit saloons and other locations to sell your product
5. **Avoiding Law Enforcement**: Keep distilleries hidden and be careful when selling

### For Law Enforcement
- **Discovering Distilleries**: Get close to distilleries to have a chance of discovering them
- **Raiding Distilleries**: Interact with discovered distilleries to raid them
- **Confiscating Products**: Raids will confiscate moonshine and may destroy the distillery

### Admin Commands
- `/moonshinelist` - List all distilleries with details
- `/moonshineremove [id]` - Remove a specific distillery
- `/moonshinegoto [id]` - Teleport to a distillery location

## Configuration

### Placement Settings
```lua
Config.Placement = {
    maxDistilleries = 2,           -- Max distilleries per player
    minDistanceFromTowns = 500,    -- Distance from towns (meters)
    minDistanceFromRoads = 100,    -- Distance from roads (meters)
    minDistanceBetween = 200,      -- Distance between distilleries
    requiredItems = {              -- Items needed to place
        ['distillery_kit'] = 1,
        ['wood'] = 10,
        ['metal'] = 5
    }
}
```

### Production Settings changing this does nothing config.lua is where its at 
```lua
Config.Production = {
    baseTime = 30,                 -- Base production time (minutes)
    recipes = {
        basic = {
            ingredients = {corn = 5, sugar = 3, yeast = 1, water = 2, wood = 3},
            time = 30,
            yield = 3,
            quality_base = 50
        }
    }
}
```

### Law Enforcement Settings
```lua
Config.LawEnforcement = {
    discoveryChance = 15,          -- % chance per hour of discovery
    raidNotificationTime = 300,    -- Seconds warning before raid
    confiscationRate = 0.8,        -- % of products confiscated
    destructionChance = 0.3        -- % chance distillery is destroyed
}
```

## Dependencies

- QBCore Framework
- oxmysql
- qb-menu (for interaction menus)

## Support

This script includes comprehensive error handling, logging, and cleanup systems. Check the server console for any error messages or issues.

## Version History

- v1.0.0 - Initial release with full moonshine distillery system

## License

This project is licensed under the MIT License.
