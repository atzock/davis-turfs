ESX = nil
local PlayerData = {}
local dealerPeds = {}
local dealerBlips = {}
local isCapturing = false
local captureTimer = 0

-- Initialize ESX
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

-- Update player data on job change
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Create dealer NPCs and blips
Citizen.CreateThread(function()
    -- Wait for ESX to be ready
    while ESX == nil do
        Citizen.Wait(100)
    end

    -- Load ped models
    for _, dealer in pairs(Config.Dealers) do
        RequestModel(GetHashKey(dealer.ped))
        while not HasModelLoaded(GetHashKey(dealer.ped)) do
            Wait(1)
        end
    end

    -- Create dealer peds
    for _, dealer in pairs(Config.Dealers) do
        local ped = CreatePed(4, GetHashKey(dealer.ped), dealer.coords.x, dealer.coords.y, dealer.coords.z, dealer.coords.w, false, true)
        SetEntityHeading(ped, dealer.coords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        dealerPeds[dealer.id] = ped

        -- Create blip
        local blip = AddBlipForCoord(dealer.blipCoords.x, dealer.blipCoords.y, dealer.blipCoords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, Config.Blip.display)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(dealer.name)
        EndTextCommandSetBlipName(blip)
        
        dealerBlips[dealer.id] = blip
    end
end)

-- Main interaction thread
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, dealer in pairs(Config.Dealers) do
            local distance = #(playerCoords - vector3(dealer.coords.x, dealer.coords.y, dealer.coords.z))

            if distance < Config.Marker.drawDistance then
                sleep = 0
                
                -- Draw marker
                DrawMarker(
                    Config.Marker.type,
                    dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                    false, true, 2, false, nil, nil, false
                )

                if distance < Config.Marker.interactDistance then
                    -- Show help text
                    if not isCapturing then
                        ESX.ShowHelpNotification(Config.Locale['press_e_sell'])
                    end

                    -- Sell drugs
                    if IsControlJustReleased(0, 38) and not isCapturing then -- E key
                        OpenSellMenu(dealer)
                    end

                    -- Capture dealer (hold H key)
                    if IsControlPressed(0, 74) and not isCapturing then -- H key
                        StartCapture(dealer)
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Open the drug selling menu
function OpenSellMenu(dealer)
    ESX.TriggerServerCallback('davis_turfs:getDealerInfo', function(dealerInfo)
        ESX.TriggerServerCallback('davis_turfs:getPlayerInventory', function(inventory)
            local elements = {}
            local hasDrugs = false

            -- Only show the drug that this dealer buys
            for _, drug in pairs(Config.Drugs) do
                if drug.item == dealer.drug then
                    local count = 0
                    
                    -- Find the drug in player's inventory
                    for _, item in pairs(inventory) do
                        if item.name == drug.item then
                            count = item.count
                            break
                        end
                    end

                    if count > 0 then
                        hasDrugs = true
                        table.insert(elements, {
                            label = drug.label .. ' - $' .. drug.price .. ' each (' .. count .. ' available)',
                            value = drug.item,
                            price = drug.price,
                            count = count,
                            drugLabel = drug.label
                        })
                    end
                end
            end

            if not hasDrugs then
                ESX.ShowNotification(Config.Locale['no_drugs'])
                return
            end

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'drug_sell_menu', {
                title    = dealer.name,
                align    = 'top-left',
                elements = elements
            }, function(data, menu)
                local selectedDrug = data.current.value
                
                -- Ask how many to sell
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'drug_sell_amount', {
                    title = 'How many ' .. data.current.drugLabel .. ' to sell?'
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)

                    if amount == nil or amount <= 0 then
                        ESX.ShowNotification('Invalid amount')
                        return
                    end

                    menu2.close()
                    menu.close()

                    -- Send to server for validation and processing
                    TriggerServerEvent('davis_turfs:sellDrugs', dealer.id, selectedDrug, amount)
                end, function(data2, menu2)
                    menu2.close()
                end)
            end, function(data, menu)
                menu.close()
            end)
        end)
    end, dealer.id)
end

-- Start capturing a dealer
function StartCapture(dealer)
    ESX.TriggerServerCallback('davis_turfs:canCapture', function(canCapture, message)
        if not canCapture then
            ESX.ShowNotification(message or Config.Locale['not_authorized'])
            return
        end

        isCapturing = true
        captureTimer = Config.CaptureTime
        local playerPed = PlayerPedId()
        local startCoords = GetEntityCoords(playerPed)

        -- Capture progress thread
        Citizen.CreateThread(function()
            while captureTimer > 0 and isCapturing do
                Citizen.Wait(1000)
                captureTimer = captureTimer - 1
                
                -- Check if player moved too far
                local currentCoords = GetEntityCoords(PlayerPedId())
                if #(currentCoords - startCoords) > 5.0 then
                    isCapturing = false
                    ESX.ShowNotification(Config.Locale['capture_cancelled'])
                    return
                end

                -- Show progress
                ESX.ShowNotification(string.format(Config.Locale['capturing'], captureTimer))
            end

            if isCapturing and captureTimer <= 0 then
                -- Capture complete
                TriggerServerEvent('davis_turfs:captureDealer', dealer.id)
                isCapturing = false
            end
        end)
    end, dealer.id)
end

-- Receive capture completion notification
RegisterNetEvent('davis_turfs:captureComplete')
AddEventHandler('davis_turfs:captureComplete', function(success, message)
    if success then
        ESX.ShowNotification(Config.Locale['capture_complete'])
    else
        ESX.ShowNotification(message or 'Capture failed')
    end
end)

-- Receive global capture notification
RegisterNetEvent('davis_turfs:dealerCaptured')
AddEventHandler('davis_turfs:dealerCaptured', function(dealerName, jobLabel)
    ESX.ShowNotification(string.format(Config.Locale['dealer_captured'], jobLabel))
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    -- Delete dealer peds
    for _, ped in pairs(dealerPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    -- Remove blips
    for _, blip in pairs(dealerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
