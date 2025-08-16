local Translations = {
    error = {
        canceled = 'Canceled',
        no_materials = 'You don\'t have the required materials',
        too_close_town = 'Too close to town - find a more remote location',
        too_close_road = 'Too close to road - move further away',
        too_close_distillery = 'Too close to another distillery',
        max_distilleries = 'You already have the maximum number of distilleries',
        invalid_location = 'Invalid location for distillery placement',
        not_owner = 'You don\'t own this distillery',
        no_ingredients = 'Missing required ingredients',
        already_producing = 'Distillery is already producing moonshine',
        no_products = 'No moonshine ready for collection',
        inventory_full = 'Your inventory is full',
        not_law_enforcement = 'You are not authorized to do this',
        distillery_destroyed = 'This distillery has been destroyed',
        no_moonshine = 'You don\'t have any moonshine to sell',
        no_buyer = 'No buyer available at this location'
    },
    success = {
        distillery_placed = 'Distillery successfully placed',
        production_started = 'Moonshine production started',
        moonshine_collected = 'Moonshine collected successfully',
        moonshine_sold = 'Moonshine sold for $%{amount}',
        distillery_dismantled = 'Distillery dismantled',
        raid_successful = 'Distillery raided successfully'
    },
    info = {
        place_distillery = 'Place Distillery',
        distillery_menu = 'Distillery Operations',
        start_production = 'Start Production',
        check_status = 'Check Status',
        collect_moonshine = 'Collect Moonshine',
        dismantle = 'Dismantle Distillery',
        raid_distillery = 'Raid Distillery',
        sell_moonshine = 'Sell Moonshine',
        
        -- Status messages
        status_idle = 'Distillery is idle',
        status_producing = 'Producing moonshine... %{time} minutes remaining',
        status_ready = 'Moonshine ready for collection! %{bottles} bottles available',
        status_raided = 'Distillery has been raided',
        
        -- Production info
        recipe_basic = 'Basic Moonshine Recipe',
        recipe_premium = 'Premium Moonshine Recipe',
        quality_poor = 'Poor Quality',
        quality_average = 'Average Quality', 
        quality_good = 'Good Quality',
        quality_excellent = 'Excellent Quality',
        
        -- Law enforcement
        distillery_discovered = 'Illegal distillery discovered!',
        raid_incoming = 'Law enforcement raid incoming in %{time} seconds!',
        distillery_confiscated = 'Your distillery has been raided and products confiscated',
        
        -- Economy
        moonshine_price = 'Moonshine - $%{price} per bottle',
        total_sale = 'Total sale: $%{amount} for %{bottles} bottles',
        
        -- Ingredients
        corn = 'Corn',
        sugar = 'Sugar',
        yeast = 'Yeast', 
        water = 'Water',
        wood = 'Wood',
        distillery_kit = 'Distillery Kit',
        metal = 'Metal',
        moonshine = 'Moonshine'
    },
    menu = {
        distillery_operations = 'Distillery Operations',
        select_recipe = 'Select Recipe',
        confirm_production = 'Confirm Production',
        close = '⬅ Close Menu'
    },
    progress = {
        placing_distillery = 'Placing distillery...',
        starting_production = 'Starting production...',
        collecting_moonshine = 'Collecting moonshine...',
        dismantling = 'Dismantling distillery...',
        raiding = 'Raiding distillery...',
        selling_moonshine = 'Selling moonshine...'
    },
    prompts = {
        place_distillery = 'Press [E] to place distillery',
        interact_distillery = 'Press [E] to interact with distillery',
        raid_distillery = 'Press [E] to raid distillery',
        sell_moonshine = 'Press [E] to sell moonshine'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})