-- LIMOONSHINE - Moonshine Distillery System
-- Server-side main script

local QBCore = exports['qbr-core']:GetCoreObject()
local distilleries = {}
local activeProductions = {}

-- Database initialization
CreateThread(function()
    -- Create distilleries table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS moonshine_distilleries (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner VARCHAR(50) NOT NULL,
            coords_x FLOAT NOT NULL,
            coords_y FLOAT NOT NULL,
            coords_z FLOAT NOT NULL,
            heading FLOAT NOT NULL,
            status VARCHAR(20) DEFAULT 'idle',
            recipe VARCHAR(50) DEFAULT NULL,
            start_time BIGINT DEFAULT NULL,
            end_time BIGINT DEFAULT NULL,
            quality INT DEFAULT 0,
            products INT DEFAULT 0,
            discovered BOOLEAN DEFAULT FALSE,
            raid_count INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner),
            INDEX idx_status (status),
            INDEX idx_coords (coords_x, coords_y, coords_z)
        )
    ]])
    
    -- Load existing distilleries from database
    LoadDistilleries()
end)

-- Load distilleries from database with error handling
function LoadDistilleries()
    MySQL.query('SELECT * FROM moonshine_distilleries', {}, function(result)
        if result then
            local loadedCount = 0
            for _, distillery in pairs(result) do
                -- Validate distillery data
                if distillery.id and distillery.owner and distillery.coords_x and distillery.coords_y and distillery.coords_z then
                    distilleries[distillery.id] = {
                        id = distillery.id,
                        owner = distillery.owner,
                        coords = vector3(distillery.coords_x, distillery.coords_y, distillery.coords_z),
                        heading = distillery.heading or 0.0,
                        status = distillery.status or 'idle',
                        recipe = distillery.recipe,
                        startTime = distillery.start_time,
                        endTime = distillery.end_time,
                        quality = distillery.quality or 0,
                        products = distillery.products or 0,
                        discovered = distillery.discovered or false,
                        raidCount = distillery.raid_count or 0,
                        created = distillery.created_at
                    }
                    loadedCount = loadedCount + 1
                else
                    print('^1[LIMOONSHINE ERROR]^7 Invalid distillery data for ID: ' .. (distillery.id or 'unknown'))
                end
            end
            print('^2[LIMOONSHINE]^7 Loaded ' .. loadedCount .. ' distilleries from database')
        else
            print('^3[LIMOONSHINE]^7 No distilleries found in database')
        end
    end)
end

-- Database Functions
local function CreateDistillery(owner, coords, heading)
    -- Input validation
    if not owner or not coords or not heading then
        print('^1[LIMOONSHINE ERROR]^7 Invalid parameters for CreateDistillery')
        return false
    end
    
    local success, insertId = pcall(function()
        return MySQL.insert.await('INSERT INTO moonshine_distilleries (owner, coords_x, coords_y, coords_z, heading) VALUES (?, ?, ?, ?, ?)', {
            owner, coords.x, coords.y, coords.z, heading
        })
    end)
    
    if success and insertId then
        distilleries[insertId] = {
            id = insertId,
            owner = owner,
            coords = coords,
            heading = heading,
            status = 'idle',
            recipe = nil,
            startTime = nil,
            endTime = nil,
            quality = 0,
            products = 0,
            discovered = false,
            raidCount = 0,
            created = os.time()
        }
        print('^2[LIMOONSHINE]^7 Created distillery ' .. insertId .. ' for player ' .. owner)
        return insertId
    else
        print('^1[LIMOONSHINE ERROR]^7 Failed to create distillery: ' .. tostring(insertId))
        return false
    end
end

local function UpdateDistillery(id, data)
    local updateFields = {}
    local updateValues = {}
    
    for key, value in pairs(data) do
        if key == 'coords' then
            table.insert(updateFields, 'coords_x = ?')
            table.insert(updateFields, 'coords_y = ?')
            table.insert(updateFields, 'coords_z = ?')
            table.insert(updateValues, value.x)
            table.insert(updateValues, value.y)
            table.insert(updateValues, value.z)
        elseif key == 'startTime' then
            table.insert(updateFields, 'start_time = ?')
            table.insert(updateValues, value)
        elseif key == 'endTime' then
            table.insert(updateFields, 'end_time = ?')
            table.insert(updateValues, value)
        elseif key == 'raidCount' then
            table.insert(updateFields, 'raid_count = ?')
            table.insert(updateValues, value)
        else
            table.insert(updateFields, key .. ' = ?')
            table.insert(updateValues, value)
        end
    end
    
    table.insert(updateValues, id)
    local query = 'UPDATE moonshine_distilleries SET ' .. table.concat(updateFields, ', ') .. ' WHERE id = ?'
    
    MySQL.update(query, updateValues, function(affectedRows)
        if affectedRows > 0 and distilleries[id] then
            for key, value in pairs(data) do
                distilleries[id][key] = value
            end
        end
    end)
end

local function DeleteDistillery(id)
    MySQL.execute('DELETE FROM moonshine_distilleries WHERE id = ?', {id}, function(affectedRows)
        if affectedRows > 0 then
            distilleries[id] = nil
        end
    end)
end

-- Utility Functions
local function GetPlayerDistilleries(citizenId)
    local playerDistilleries = {}
    for _, distillery in pairs(distilleries) do
        if distillery.owner == citizenId then
            table.insert(playerDistilleries, distillery)
        end
    end
    return playerDistilleries
end

local function GetDistilleryById(id)
    return distilleries[id]
end

local function ValidateIngredients(recipe, playerItems)
    local recipeData = Config.Production.recipes[recipe]
    if not recipeData then return false end
    
    for ingredient, required in pairs(recipeData.ingredients) do
        local playerAmount = 0
        for _, item in pairs(playerItems) do
            if item.name == ingredient then
                playerAmount = item.amount
                break
            end
        end
        if playerAmount < required then
            return false
        end
    end
    return true
end

local function CalculateQuality(recipe, ingredients)
    local recipeData = Config.Production.recipes[recipe]
    if not recipeData then return 50 end
    
    local baseQuality = recipeData.quality_base
    local qualityBonus = 0
    
    -- Add quality bonus based on ingredient excess
    for ingredient, required in pairs(recipeData.ingredients) do
        local provided = ingredients[ingredient] or required
        if provided > required then
            qualityBonus = qualityBonus + math.min((provided - required) * 2, 10)
        end
    end
    
    return math.min(baseQuality + qualityBonus, 100)
end

-- Placement validation functions
local function IsValidPlacement(coords, citizenId)
    -- Check distance from towns
    for _, zone in pairs(Config.Placement.restrictedZones) do
        if #(coords - zone.coords) < zone.radius then
            return false, 'too_close_town'
        end
    end
    
    -- Check distance from other distilleries
    for _, distillery in pairs(distilleries) do
        if #(coords - distillery.coords) < Config.Placement.minDistanceBetween then
            return false, 'too_close_distillery'
        end
    end
    
    -- Check player's distillery count
    local playerDistilleries = GetPlayerDistilleries(citizenId)
    if #playerDistilleries >= Config.Placement.maxDistilleries then
        return false, 'max_distilleries'
    end
    
    return true, nil
end

-- Events
RegisterNetEvent('moonshine:server:placeDistillery', function(coords, heading)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local isValid, errorMsg = IsValidPlacement(coords, Player.PlayerData.citizenid)
    if not isValid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.' .. errorMsg), 'error')
        return
    end
    
    -- Check if player has required items
    local hasItems = true
    for item, amount in pairs(Config.Placement.requiredItems) do
        if Player.Functions.GetItemByName(item).amount < amount then
            hasItems = false
            break
        end
    end
    
    if not hasItems then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_materials'), 'error')
        return
    end
    
    -- Remove required items
    for item, amount in pairs(Config.Placement.requiredItems) do
        Player.Functions.RemoveItem(item, amount)
    end
    
    -- Create distillery
    local distilleryId = CreateDistillery(Player.PlayerData.citizenid, coords, heading)
    if distilleryId then
        TriggerClientEvent('moonshine:client:distilleryPlaced', src, distilleryId, coords, heading)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.distillery_placed'), 'success')
    end
end)

RegisterNetEvent('moonshine:server:requestDistilleryMenu', function(distilleryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery then return end
    
    if distillery.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    TriggerClientEvent('moonshine:client:openDistilleryMenu', src, distillery)
end)

RegisterNetEvent('moonshine:server:dismantleDistillery', function(distilleryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery or distillery.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Return some materials
    Player.Functions.AddItem('wood', 5)
    Player.Functions.AddItem('metal', 2)
    
    DeleteDistillery(distilleryId)
    TriggerClientEvent('moonshine:client:removeDistillery', src, distilleryId)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.distillery_dismantled'), 'success')
end)

RegisterNetEvent('moonshine:server:raidDistillery', function(distilleryId)
    -- Raid logic will be implemented in task 6
end)

-- Callbacks (to be implemented in later tasks)
QBCore.Functions.CreateCallback('moonshine:server:getPlayerDistilleries', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local playerDistilleries = GetPlayerDistilleries(Player.PlayerData.citizenid)
        cb(playerDistilleries)
    else
        cb({})
    end
end)

QBCore.Functions.CreateCallback('moonshine:server:getDistilleryInfo', function(source, cb, distilleryId)
    local distillery = GetDistilleryById(distilleryId)
    cb(distillery)
end)

-- Production timer system
CreateThread(function()
    while true do
        local currentTime = os.time()
        
        -- Check for completed productions
        for distilleryId, distillery in pairs(distilleries) do
            if distillery.status == 'producing' and distillery.endTime and currentTime >= distillery.endTime then
                local recipeData = Config.Production.recipes[distillery.recipe]
                if recipeData then
                    UpdateDistillery(distilleryId, {
                        status = 'ready',
                        products = recipeData.yield
                    })
                    
                    -- Notify owner if online
                    local Player = QBCore.Functions.GetPlayerByCitizenId(distillery.owner)
                    if Player then
                        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, Lang:t('info.status_ready', {bottles = recipeData.yield}), 'success')
                    end
                end
            end
        end
        
        Wait(60000) -- Check every minute
    end
end)

-- Exports for other scripts
exports('GetDistilleries', function()
    return distilleries
end)

exports('GetPlayerDistilleries', function(citizenId)
    return GetPlayerDistilleries(citizenId)
end)
RegisterNet
Event('moonshine:server:startProduction', function(distilleryId, recipe)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery or distillery.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    if distillery.status ~= 'idle' then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_producing'), 'error')
        return
    end
    
    local recipeData = Config.Production.recipes[recipe]
    if not recipeData then return end
    
    -- Check ingredients
    local hasIngredients = true
    for ingredient, required in pairs(recipeData.ingredients) do
        local item = Player.Functions.GetItemByName(ingredient)
        if not item or item.amount < required then
            hasIngredients = false
            break
        end
    end
    
    if not hasIngredients then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_ingredients'), 'error')
        return
    end
    
    -- Remove ingredients
    for ingredient, required in pairs(recipeData.ingredients) do
        Player.Functions.RemoveItem(ingredient, required)
    end
    
    -- Start production
    local startTime = os.time()
    local endTime = startTime + (recipeData.time * 60)
    local quality = CalculateQuality(recipe, recipeData.ingredients)
    
    UpdateDistillery(distilleryId, {
        status = 'producing',
        recipe = recipe,
        startTime = startTime,
        endTime = endTime,
        quality = quality
    })
    
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.production_started'), 'success')
end)

RegisterNetEvent('moonshine:server:collectMoonshine', function(distilleryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery or distillery.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    if distillery.status ~= 'ready' or distillery.products <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_products'), 'error')
        return
    end
    
    -- Add moonshine to inventory
    local info = {
        quality = distillery.quality,
        recipe = distillery.recipe
    }
    
    Player.Functions.AddItem('moonshine', distillery.products, false, info)
    
    -- Reset distillery
    UpdateDistillery(distilleryId, {
        status = 'idle',
        recipe = nil,
        startTime = nil,
        endTime = nil,
        quality = 0,
        products = 0
    })
    
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.moonshine_collected'), 'success')
end)-- Law En
forcement Functions
local function IsLawEnforcement(Player)
    for _, job in pairs(Config.LawEnforcement.allowedJobs) do
        if Player.PlayerData.job.name == job then
            return true
        end
    end
    return false
end

RegisterNetEvent('moonshine:server:raidDistillery', function(distilleryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not IsLawEnforcement(Player) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_law_enforcement'), 'error')
        return
    end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.distillery_destroyed'), 'error')
        return
    end
    
    -- Confiscate products
    local confiscatedAmount = 0
    if distillery.products > 0 then
        confiscatedAmount = math.floor(distillery.products * Config.LawEnforcement.confiscationRate)
        Player.Functions.AddItem('moonshine', confiscatedAmount)
    end
    
    -- Notify owner
    local Owner = QBCore.Functions.GetPlayerByCitizenId(distillery.owner)
    if Owner then
        TriggerClientEvent('QBCore:Notify', Owner.PlayerData.source, Lang:t('info.distillery_confiscated'), 'error')
    end
    
    -- Chance to destroy distillery
    local shouldDestroy = math.random() < Config.LawEnforcement.destructionChance
    if shouldDestroy then
        DeleteDistillery(distilleryId)
        TriggerClientEvent('moonshine:client:removeDistillery', -1, distilleryId)
    else
        -- Mark as discovered and raided
        UpdateDistillery(distilleryId, {
            status = 'raided',
            products = 0,
            discovered = true,
            raidCount = distillery.raidCount + 1
        })
    end
    
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.raid_successful'), 'success')
end)

RegisterNetEvent('moonshine:server:discoverDistillery', function(distilleryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not IsLawEnforcement(Player) then return end
    
    local distillery = GetDistilleryById(distilleryId)
    if not distillery then return end
    
    UpdateDistillery(distilleryId, {discovered = true})
    
    -- Alert other law enforcement
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if IsLawEnforcement(player) then
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Lang:t('info.distillery_discovered'), 'primary')
        end
    end
end)-- Econom
y System
RegisterNetEvent('moonshine:server:sellMoonshine', function(locationIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local moonshine = Player.Functions.GetItemByName('moonshine')
    if not moonshine or moonshine.amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_moonshine'), 'error')
        return
    end
    
    local location = Config.Economy.sellingLocations[locationIndex]
    if not location then return end
    
    -- Calculate price based on quality
    local info = moonshine.info or {}
    local quality = info.quality or 50
    local basePrice = Config.Economy.basePrice
    local qualityMultiplier = 1 + ((quality - 50) / 100) * Config.Economy.qualityMultiplier
    local pricePerBottle = math.floor(basePrice * qualityMultiplier)
    local totalPrice = pricePerBottle * moonshine.amount
    
    -- Law enforcement risk
    if math.random(100) <= Config.Economy.lawEnforcementRisk then
        -- Alert law enforcement
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            if IsLawEnforcement(player) then
                local coords = GetEntityCoords(GetPlayerPed(src))
                TriggerClientEvent('moonshine:client:lawEnforcementAlert', player.PlayerData.source, coords, 'Illegal moonshine sale reported')
            end
        end
    end
    
    -- Complete sale
    Player.Functions.RemoveItem('moonshine', moonshine.amount)
    Player.Functions.AddMoney('cash', totalPrice)
    
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.moonshine_sold', {amount = totalPrice}), 'success')
end)-- Adm
in Commands
QBCore.Commands.Add('moonshinelist', 'List all distilleries (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    local count = 0
    for _, distillery in pairs(distilleries) do
        count = count + 1
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            multiline = true,
            args = {'MOONSHINE', string.format('ID: %d | Owner: %s | Status: %s | Coords: %.2f, %.2f, %.2f', 
                distillery.id, distillery.owner, distillery.status, distillery.coords.x, distillery.coords.y, distillery.coords.z)}
        })
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Total distilleries: %d', count), 'primary')
end, 'admin')

QBCore.Commands.Add('moonshineremove', 'Remove a distillery (Admin Only)', {{name = 'id', help = 'Distillery ID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    local distilleryId = tonumber(args[1])
    if not distilleryId or not distilleries[distilleryId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid distillery ID', 'error')
        return
    end
    
    DeleteDistillery(distilleryId)
    TriggerClientEvent('moonshine:client:removeDistillery', -1, distilleryId)
    TriggerClientEvent('QBCore:Notify', src, string.format('Distillery %d removed', distilleryId), 'success')
end, 'admin')

QBCore.Commands.Add('moonshinegoto', 'Teleport to distillery (Admin Only)', {{name = 'id', help = 'Distillery ID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    local distilleryId = tonumber(args[1])
    if not distilleryId or not distilleries[distilleryId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid distillery ID', 'error')
        return
    end
    
    local coords = distilleries[distilleryId].coords
    SetEntityCoords(GetPlayerPed(src), coords.x, coords.y, coords.z)
    TriggerClientEvent('QBCore:Notify', src, string.format('Teleported to distillery %d', distilleryId), 'success')
end, 'admin')

-- Cleanup system for abandoned distilleries
CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        local currentTime = os.time()
        local cleanupTime = 7 * 24 * 60 * 60 -- 7 days in seconds
        
        for distilleryId, distillery in pairs(distilleries) do
            -- Check if distillery is abandoned (owner hasn't been online for 7 days)
            local lastSeen = MySQL.scalar.await('SELECT last_updated FROM players WHERE citizenid = ?', {distillery.owner})
            if lastSeen and (currentTime - lastSeen) > cleanupTime then
                DeleteDistillery(distilleryId)
                TriggerClientEvent('moonshine:client:removeDistillery', -1, distilleryId)
                print(string.format('^3[LIMOONSHINE]^7 Cleaned up abandoned distillery %d (owner: %s)', distilleryId, distillery.owner))
            end
        end
    end
end)-
- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print('^3[LIMOONSHINE]^7 Player ' .. Player.PlayerData.citizenid .. ' disconnected, cleaning up data')
        -- Any cleanup needed for disconnected players can be added here
    end
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^3[LIMOONSHINE]^7 Resource stopping, cleaning up objects')
        -- Cleanup any spawned objects
        TriggerClientEvent('moonshine:client:cleanup', -1)
    end
end)

-- Error logging function
local function LogError(functionName, error, additionalInfo)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logMessage = string.format('[%s] ERROR in %s: %s', timestamp, functionName, tostring(error))
    if additionalInfo then
        logMessage = logMessage .. ' | Additional Info: ' .. tostring(additionalInfo)
    end
    print('^1[LIMOONSHINE ERROR]^7 ' .. logMessage)
end

-- Validate configuration on startup
CreateThread(function()
    Wait(1000) -- Wait for config to load
    
    local configValid = true
    
    -- Validate placement config
    if not Config.Placement or not Config.Placement.maxDistilleries or Config.Placement.maxDistilleries <= 0 then
        LogError('Config Validation', 'Invalid placement configuration')
        configValid = false
    end
    
    -- Validate production config
    if not Config.Production or not Config.Production.recipes or not next(Config.Production.recipes) then
        LogError('Config Validation', 'Invalid production configuration')
        configValid = false
    end
    
    -- Validate economy config
    if not Config.Economy or not Config.Economy.sellingLocations or not next(Config.Economy.sellingLocations) then
        LogError('Config Validation', 'Invalid economy configuration')
        configValid = false
    end
    
    if configValid then
        print('^2[LIMOONSHINE]^7 Configuration validation passed')
    else
        print('^1[LIMOONSHINE ERROR]^7 Configuration validation failed - check your config.lua')
    end
end)-- Load a
ll distilleries on player join and send to client
RegisterNetEvent('moonshine:server:requestDistilleries', function()
    local src = source
    local nearbyDistilleries = {}
    
    for distilleryId, distillery in pairs(distilleries) do
        table.insert(nearbyDistilleries, {
            id = distilleryId,
            coords = distillery.coords,
            heading = distillery.heading,
            status = distillery.status
        })
    end
    
    TriggerClientEvent('moonshine:client:loadDistilleries', src, nearbyDistilleries)
end)

-- Optimized distance checking for law enforcement discovery
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            if IsLawEnforcement(player) then
                local playerCoords = GetEntityCoords(GetPlayerPed(player.PlayerData.source))
                
                for distilleryId, distillery in pairs(distilleries) do
                    if not distillery.discovered then
                        local distance = #(playerCoords - distillery.coords)
                        if distance < 50 then -- Within 50 meters
                            local discoveryChance = Config.LawEnforcement.discoveryChance
                            if math.random(100) <= discoveryChance then
                                TriggerEvent('moonshine:server:discoverDistillery', distilleryId)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)-- 
Create useable item for distillery kit
QBCore.Functions.CreateUseableItem('distillery_kit', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.GetItemByName(item.name) then
        TriggerClientEvent('moonshine:client:useDistilleryKit', src)
    end
end)

-- Create useable moonshine item
QBCore.Functions.CreateUseableItem('moonshine', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.GetItemByName(item.name) then
        -- Drinking moonshine could have effects
        Player.Functions.RemoveItem('moonshine', 1)
        TriggerClientEvent('QBCore:Notify', src, 'You drink some moonshine... *hic*', 'success')
        -- Add drunk effects here if desired
    end
end)