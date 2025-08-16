-- LIMOONSHINE - Moonshine Distillery System
-- Client-side main script

local QBCore = exports['qbr-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local nearbyDistilleries = {}
local placingDistillery = false

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Main thread for distillery interactions
CreateThread(function()
    while true do
        local sleep = 1000
        
        if isLoggedIn then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearDistillery = nil
            
            -- Check for nearby distilleries
            for distilleryId, distillery in pairs(nearbyDistilleries) do
                local distance = #(playerCoords - distillery.coords)
                if distance < Config.Objects.interactionDistance then
                    nearDistillery = distilleryId
                    sleep = 0
                    
                    -- Check if player is law enforcement
                    if PlayerData.job and (PlayerData.job.name == 'police' or PlayerData.job.name == 'sheriff') then
                        DrawText3D(distillery.coords.x, distillery.coords.y, distillery.coords.z + 1.0, Lang:t('prompts.raid_distillery'))
                        
                        if IsControlJustPressed(0, Config.Objects.promptKey) then
                            TriggerServerEvent('moonshine:server:raidDistillery', distilleryId)
                        end
                    else
                        -- Regular player interaction
                        DrawText3D(distillery.coords.x, distillery.coords.y, distillery.coords.z + 1.0, Lang:t('prompts.interact_distillery'))
                        
                        if IsControlJustPressed(0, Config.Objects.promptKey) then
                            TriggerServerEvent('moonshine:server:requestDistilleryMenu', distilleryId)
                        end
                    end
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Menu system
local function OpenDistilleryMenu(distilleryData)
    local menuOptions = {}
    
    if distilleryData.status == 'idle' then
        table.insert(menuOptions, {
            header = Lang:t('info.start_production'),
            txt = Lang:t('info.recipe_basic'),
            params = {
                event = 'moonshine:client:selectRecipe',
                args = {distilleryId = distilleryData.id}
            }
        })
    elseif distilleryData.status == 'producing' then
        local timeLeft = math.ceil((distilleryData.endTime - os.time()) / 60)
        table.insert(menuOptions, {
            header = Lang:t('info.status_producing', {time = timeLeft}),
            txt = 'Production in progress...',
            disabled = true
        })
    elseif distilleryData.status == 'ready' then
        table.insert(menuOptions, {
            header = Lang:t('info.collect_moonshine'),
            txt = Lang:t('info.status_ready', {bottles = distilleryData.products}),
            params = {
                event = 'moonshine:client:collectMoonshine',
                args = {distilleryId = distilleryData.id}
            }
        })
    end
    
    table.insert(menuOptions, {
        header = Lang:t('info.dismantle'),
        txt = 'Remove this distillery',
        params = {
            event = 'moonshine:client:dismantleDistillery',
            args = {distilleryId = distilleryData.id}
        }
    })
    
    exports['qb-menu']:openMenu(menuOptions)
end

local function OpenRecipeMenu(distilleryId)
    local menuOptions = {}
    
    for recipeKey, recipe in pairs(Config.Production.recipes) do
        local ingredientText = ""
        for ingredient, amount in pairs(recipe.ingredients) do
            ingredientText = ingredientText .. Lang:t('info.' .. ingredient) .. ': ' .. amount .. ' '
        end
        
        table.insert(menuOptions, {
            header = recipe.name,
            txt = ingredientText,
            params = {
                event = 'moonshine:client:startProduction',
                args = {distilleryId = distilleryId, recipe = recipeKey}
            }
        })
    end
    
    exports['qb-menu']:openMenu(menuOptions)
end

-- Utility Functions
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
        SetTextCentre(1)
        DisplayText(str, _x, _y)
    end
end

-- Placement system
local function StartDistilleryPlacement()
    placingDistillery = true
    local playerPed = PlayerPedId()
    
    QBCore.Functions.Notify(Lang:t('info.place_distillery'), 'primary')
    
    CreateThread(function()
        while placingDistillery do
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            -- Draw placement preview
            DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
            
            -- Instructions
            DrawText3D(coords.x, coords.y, coords.z + 1.0, Lang:t('prompts.place_distillery'))
            
            if IsControlJustPressed(0, Config.Objects.promptKey) then
                TriggerServerEvent('moonshine:server:placeDistillery', coords, heading)
                placingDistillery = false
            elseif IsControlJustPressed(0, 0x156F7119) then -- Escape key
                placingDistillery = false
                QBCore.Functions.Notify(Lang:t('error.canceled'), 'error')
            end
            
            Wait(0)
        end
    end)
end

-- Events
RegisterNetEvent('moonshine:client:placeDistillery', function()
    StartDistilleryPlacement()
end)

RegisterNetEvent('moonshine:client:distilleryPlaced', function(distilleryId, coords, heading)
    -- Spawn distillery object
    local model = Config.Objects.distilleryModel
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local distilleryObj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(distilleryObj, heading)
    FreezeEntityPosition(distilleryObj, true)
    
    -- Store in nearby distilleries
    nearbyDistilleries[distilleryId] = {
        id = distilleryId,
        coords = coords,
        object = distilleryObj
    }
end)

RegisterNetEvent('moonshine:client:openDistilleryMenu', function(distilleryData)
    OpenDistilleryMenu(distilleryData)
end)

RegisterNetEvent('moonshine:client:selectRecipe', function(data)
    OpenRecipeMenu(data.distilleryId)
end)

RegisterNetEvent('moonshine:client:startProduction', function(data)
    TriggerServerEvent('moonshine:server:startProduction', data.distilleryId, data.recipe)
end)

RegisterNetEvent('moonshine:client:collectMoonshine', function(data)
    TriggerServerEvent('moonshine:server:collectMoonshine', data.distilleryId)
end)

RegisterNetEvent('moonshine:client:dismantleDistillery', function(data)
    TriggerServerEvent('moonshine:server:dismantleDistillery', data.distilleryId)
end)

RegisterNetEvent('moonshine:client:updateDistilleryStatus', function()
    -- Status update logic will be implemented in task 5
end)

-- Exports for other scripts
exports('GetNearbyDistilleries', function()
    return nearbyDistilleries
end)

exports('IsPlacingDistillery', function()
    return placingDistillery
end)Regist
erNetEvent('moonshine:client:removeDistillery', function(distilleryId)
    if nearbyDistilleries[distilleryId] then
        if DoesEntityExist(nearbyDistilleries[distilleryId].object) then
            DeleteEntity(nearbyDistilleries[distilleryId].object)
        end
        nearbyDistilleries[distilleryId] = nil
    end
end)-- Econom
y system - selling locations
CreateThread(function()
    while true do
        local sleep = 1000
        
        if isLoggedIn then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for i, location in pairs(Config.Economy.sellingLocations) do
                local distance = #(playerCoords - location.coords)
                if distance < 3.0 then
                    sleep = 0
                    DrawText3D(location.coords.x, location.coords.y, location.coords.z + 1.0, Lang:t('prompts.sell_moonshine'))
                    
                    if IsControlJustPressed(0, Config.Objects.promptKey) then
                        TriggerServerEvent('moonshine:server:sellMoonshine', i)
                    end
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('moonshine:client:lawEnforcementAlert', function(coords, message)
    -- Create blip for law enforcement
    local blip = N_0x554d9d53f696d002(1664425300, coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 960467426, 1)
    SetBlipScale(blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, message)
    
    -- Remove blip after 5 minutes
    SetTimeout(300000, function()
        RemoveBlip(blip)
    end)
    
    QBCore.Functions.Notify(message, 'primary')
end)-- Err
or handling and cleanup
RegisterNetEvent('moonshine:client:cleanup', function()
    -- Cleanup all spawned distillery objects
    for distilleryId, distillery in pairs(nearbyDistilleries) do
        if DoesEntityExist(distillery.object) then
            DeleteEntity(distillery.object)
        end
    end
    nearbyDistilleries = {}
    placingDistillery = false
end)

-- Resource restart handling
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Cleanup on resource stop
        for distilleryId, distillery in pairs(nearbyDistilleries) do
            if DoesEntityExist(distillery.object) then
                DeleteEntity(distillery.object)
            end
        end
    end
end)-
- Load distilleries when player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    
    -- Request distilleries from server
    Wait(2000) -- Wait for everything to load
    TriggerServerEvent('moonshine:server:requestDistilleries')
end)

-- Load distilleries from server
RegisterNetEvent('moonshine:client:loadDistilleries', function(distilleryData)
    for _, distillery in pairs(distilleryData) do
        local model = Config.Objects.distilleryModel
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        local distilleryObj = CreateObject(model, distillery.coords.x, distillery.coords.y, distillery.coords.z, false, false, false)
        SetEntityHeading(distilleryObj, distillery.heading)
        FreezeEntityPosition(distilleryObj, true)
        
        nearbyDistilleries[distillery.id] = {
            id = distillery.id,
            coords = distillery.coords,
            object = distilleryObj,
            status = distillery.status
        }
    end
    
    print('^2[LIMOONSHINE]^7 Loaded ' .. #distilleryData .. ' distilleries on client')
end)

-- Add item usage for distillery kit
RegisterNetEvent('moonshine:client:useDistilleryKit', function()
    if placingDistillery then
        QBCore.Functions.Notify(Lang:t('error.already_placing'), 'error')
        return
    end
    
    StartDistilleryPlacement()
end)