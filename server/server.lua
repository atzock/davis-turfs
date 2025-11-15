ESX = nil
local dealerOwnership = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Load dealer ownership from database on server start
Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM dealer_ownership', {}, function(results)
        for _, row in ipairs(results) do
            dealerOwnership[row.dealer_id] = row.owner_job
        end
        print('[Davis Turfs] Loaded ' .. #results .. ' dealer ownership records')
    end)
end)

-- Get player inventory callback
ESX.RegisterServerCallback('davis_turfs:getPlayerInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({})
        return
    end

    local inventory = xPlayer.inventory
    cb(inventory)
end)

-- Get dealer info callback
ESX.RegisterServerCallback('davis_turfs:getDealerInfo', function(source, cb, dealerId)
    local owner = dealerOwnership[dealerId]
    local dealerConfig = nil
    
    for _, dealer in pairs(Config.Dealers) do
        if dealer.id == dealerId then
            dealerConfig = dealer
            break
        end
    end

    cb({
        owner = owner,
        dealer = dealerConfig
    })
end)

-- Can player capture dealer callback
ESX.RegisterServerCallback('davis_turfs:canCapture', function(source, cb, dealerId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false, 'Player not found')
        return
    end

    -- Check if player has required job
    local hasRequiredJob = false
    if type(Config.CaptureJob) == 'table' then
        for _, job in pairs(Config.CaptureJob) do
            if xPlayer.job.name == job then
                hasRequiredJob = true
                break
            end
        end
    else
        hasRequiredJob = xPlayer.job.name == Config.CaptureJob
    end

    if not hasRequiredJob then
        cb(false, Config.Locale['not_authorized'])
        return
    end

    -- Check if already owned by this faction
    if dealerOwnership[dealerId] == xPlayer.job.name then
        cb(false, Config.Locale['already_owned'])
        return
    end

    cb(true)
end)

-- Sell drugs event
RegisterNetEvent('davis_turfs:sellDrugs')
AddEventHandler('davis_turfs:sellDrugs', function(dealerId, drugItem, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        return
    end

    -- Validate dealer exists
    local dealer = nil
    for _, d in pairs(Config.Dealers) do
        if d.id == dealerId then
            dealer = d
            break
        end
    end

    if not dealer then
        print('[Davis Turfs] Invalid dealer ID: ' .. dealerId)
        return
    end

    -- Validate that this dealer buys this drug
    if dealer.drug ~= drugItem then
        xPlayer.showNotification('This dealer doesn\'t buy that drug')
        return
    end

    -- Validate drug exists in config
    local drugConfig = nil
    for _, drug in pairs(Config.Drugs) do
        if drug.item == drugItem then
            drugConfig = drug
            break
        end
    end

    if not drugConfig then
        print('[Davis Turfs] Invalid drug item: ' .. drugItem)
        return
    end

    -- Validate amount
    if amount <= 0 then
        xPlayer.showNotification('Invalid amount')
        return
    end

    -- Check if player has the drugs
    local playerItem = xPlayer.getInventoryItem(drugItem)
    if not playerItem or playerItem.count < amount then
        xPlayer.showNotification(Config.Locale['not_enough_drugs'])
        return
    end

    -- Calculate earnings
    local totalPrice = drugConfig.price * amount
    local playerEarnings = math.floor(totalPrice * (Config.PlayerCut / 100))
    local factionEarnings = math.floor(totalPrice * (Config.FactionCut / 100))

    -- Remove drugs from player
    xPlayer.removeInventoryItem(drugItem, amount)

    -- Give money to player
    if Config.MoneyType == 'black_money' then
        xPlayer.addAccountMoney('black_money', playerEarnings)
    else
        xPlayer.addMoney(playerEarnings)
    end

    -- Notify player
    xPlayer.showNotification(string.format(Config.Locale['sold_drugs'], amount, drugConfig.label, playerEarnings))

    -- Handle faction earnings
    local ownerJob = dealerOwnership[dealerId]
    if ownerJob then
        if Config.UseSocietyAccount then
            -- Add money to society account
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. ownerJob, function(account)
                if account then
                    account.addMoney(factionEarnings)
                    
                    -- Notify online faction members
                    local xPlayers = ESX.GetPlayers()
                    for _, playerId in ipairs(xPlayers) do
                        local xTarget = ESX.GetPlayerFromId(playerId)
                        if xTarget and xTarget.job.name == ownerJob then
                            xTarget.showNotification(string.format(Config.Locale['earnings_received'], factionEarnings))
                        end
                    end
                end
            end)
        else
            -- Store in custom database table
            MySQL.Async.execute('INSERT INTO faction_earnings (job, amount) VALUES (@job, @amount) ON DUPLICATE KEY UPDATE amount = amount + @amount', {
                ['@job'] = ownerJob,
                ['@amount'] = factionEarnings
            }, function(rowsChanged)
                -- Notify online faction members
                local xPlayers = ESX.GetPlayers()
                for _, playerId in ipairs(xPlayers) do
                    local xTarget = ESX.GetPlayerFromId(playerId)
                    if xTarget and xTarget.job.name == ownerJob then
                        xTarget.showNotification(string.format(Config.Locale['earnings_received'], factionEarnings))
                    end
                end
            end)
        end
    end

    -- Log the transaction
    print(string.format('[Davis Turfs] %s sold %sx %s for $%s (Player: $%s, Faction: $%s)', 
        GetPlayerName(_source), amount, drugItem, totalPrice, playerEarnings, factionEarnings))
end)

-- Capture dealer event
RegisterNetEvent('davis_turfs:captureDealer')
AddEventHandler('davis_turfs:captureDealer', function(dealerId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        return
    end

    -- Validate dealer exists
    local dealer = nil
    for _, d in pairs(Config.Dealers) do
        if d.id == dealerId then
            dealer = d
            break
        end
    end

    if not dealer then
        TriggerClientEvent('davis_turfs:captureComplete', _source, false, 'Invalid dealer')
        return
    end

    -- Check if player has required job
    local hasRequiredJob = false
    if type(Config.CaptureJob) == 'table' then
        for _, job in pairs(Config.CaptureJob) do
            if xPlayer.job.name == job then
                hasRequiredJob = true
                break
            end
        end
    else
        hasRequiredJob = xPlayer.job.name == Config.CaptureJob
    end

    if not hasRequiredJob then
        TriggerClientEvent('davis_turfs:captureComplete', _source, false, Config.Locale['not_authorized'])
        return
    end

    -- Check if already owned by this faction
    if dealerOwnership[dealerId] == xPlayer.job.name then
        TriggerClientEvent('davis_turfs:captureComplete', _source, false, Config.Locale['already_owned'])
        return
    end

    -- Update database
    MySQL.Async.execute('INSERT INTO dealer_ownership (dealer_id, owner_job) VALUES (@dealer_id, @owner_job) ON DUPLICATE KEY UPDATE owner_job = @owner_job, captured_at = CURRENT_TIMESTAMP', {
        ['@dealer_id'] = dealerId,
        ['@owner_job'] = xPlayer.job.name
    }, function(rowsChanged)
        -- Update local cache
        dealerOwnership[dealerId] = xPlayer.job.name

        -- Notify the capturing player
        TriggerClientEvent('davis_turfs:captureComplete', _source, true)

        -- Broadcast to all players
        TriggerClientEvent('davis_turfs:dealerCaptured', -1, dealer.name, xPlayer.job.label)

        -- Log the capture
        print(string.format('[Davis Turfs] %s (%s) captured dealer %s', 
            GetPlayerName(_source), xPlayer.job.label, dealer.name))
    end)
end)

-- Command to check dealer ownership (admin/debug)
ESX.RegisterCommand('checkdealers', 'admin', function(xPlayer, args, showError)
    for dealerId, ownerJob in pairs(dealerOwnership) do
        local dealerName = 'Unknown'
        for _, dealer in pairs(Config.Dealers) do
            if dealer.id == dealerId then
                dealerName = dealer.name
                break
            end
        end
        xPlayer.showNotification(dealerName .. ' is owned by ' .. ownerJob)
    end
end, false, {help = 'Check dealer ownership status'})

-- Command to reset dealer ownership (admin)
ESX.RegisterCommand('resetdealer', 'admin', function(xPlayer, args, showError)
    local dealerId = tonumber(args.dealerid)
    
    if not dealerId then
        xPlayer.showNotification('Usage: /resetdealer [dealer_id]')
        return
    end

    MySQL.Async.execute('DELETE FROM dealer_ownership WHERE dealer_id = @dealer_id', {
        ['@dealer_id'] = dealerId
    }, function(rowsChanged)
        dealerOwnership[dealerId] = nil
        xPlayer.showNotification('Dealer ' .. dealerId .. ' ownership reset')
        print(string.format('[Davis Turfs] Admin %s reset dealer %s', GetPlayerName(xPlayer.source), dealerId))
    end)
end, false, {help = 'Reset dealer ownership', validate = true, arguments = {
    {name = 'dealerid', help = 'The dealer ID to reset', type = 'number'}
}})

-- API function to get dealer ownership (for other scripts)
function GetDealerOwnership(dealerId)
    return dealerOwnership[dealerId]
end

-- API function to get all dealer ownership
function GetAllDealerOwnership()
    return dealerOwnership
end

-- Export functions
exports('GetDealerOwnership', GetDealerOwnership)
exports('GetAllDealerOwnership', GetAllDealerOwnership)
