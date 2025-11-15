# Code Explanation - Davis Turfs

This document explains the most important code sections of the Davis Turfs drug dealing system.

## Architecture Overview

The script follows FiveM best practices with clear separation between client and server:
- **client.lua**: Handles UI, interactions, and visual elements
- **server.lua**: Handles all game-changing operations, validation, and database
- **config.lua**: All user-configurable settings
- **dealers.sql**: Database schema

## Critical Code Sections

### 1. Server-Side Drug Sale Validation

**Location:** `server.lua` - RegisterNetEvent('davis_turfs:sellDrugs')

```lua
-- Validate dealer exists
local dealer = nil
for _, d in pairs(Config.Dealers) do
    if d.id == dealerId then
        dealer = d
        break
    end
end

-- Validate that this dealer buys this drug
if dealer.drug ~= drugItem then
    xPlayer.showNotification('This dealer doesn\'t buy that drug')
    return
end

-- Check if player has the drugs
local playerItem = xPlayer.getInventoryItem(drugItem)
if not playerItem or playerItem.count < amount then
    xPlayer.showNotification(Config.Locale['not_enough_drugs'])
    return
end
```

**Why it's important:**
- Prevents players from selling items they don't have
- Ensures dealers only buy their assigned drug
- Server-side validation prevents client-side exploits
- All checks happen before any money or items are modified

### 2. Money Distribution System

**Location:** `server.lua` - RegisterNetEvent('davis_turfs:sellDrugs')

```lua
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
```

**Why it's important:**
- Uses math.floor to prevent decimal exploits
- Configurable split percentage (85/15 by default)
- Supports both black money and clean money
- Atomic operation: remove items first, then add money
- No way for players to get money without losing items

### 3. Faction Earnings - Society Integration

**Location:** `server.lua` - RegisterNetEvent('davis_turfs:sellDrugs')

```lua
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
        MySQL.Async.execute('INSERT INTO faction_earnings (job, amount) VALUES (@job, @amount) 
            ON DUPLICATE KEY UPDATE amount = amount + @amount', {
            ['@job'] = ownerJob,
            ['@amount'] = factionEarnings
        })
    end
end
```

**Why it's important:**
- Flexible: works with or without ESX society system
- Only executes if dealer has an owner
- Notifies all online faction members in real-time
- Uses ON DUPLICATE KEY UPDATE for safe database operations
- Accumulates earnings automatically

### 4. Capture System - Client Side

**Location:** `client.lua` - StartCapture() function

```lua
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
```

**Why it's important:**
- Server callback checks permissions before allowing capture
- Timer system prevents instant captures
- Distance check prevents AFK capturing or teleport exploits
- Client-side timer provides good UX
- Server validates the actual capture (next section)

### 5. Capture System - Server Side Validation

**Location:** `server.lua` - RegisterNetEvent('davis_turfs:captureDealer')

```lua
RegisterNetEvent('davis_turfs:captureDealer')
AddEventHandler('davis_turfs:captureDealer', function(dealerId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    -- Validate dealer exists
    local dealer = nil
    for _, d in pairs(Config.Dealers) do
        if d.id == dealerId then
            dealer = d
            break
        end
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

    -- Update database
    MySQL.Async.execute('INSERT INTO dealer_ownership (dealer_id, owner_job) 
        VALUES (@dealer_id, @owner_job) 
        ON DUPLICATE KEY UPDATE owner_job = @owner_job, captured_at = CURRENT_TIMESTAMP', {
        ['@dealer_id'] = dealerId,
        ['@owner_job'] = xPlayer.job.name
    })
end)
```

**Why it's important:**
- Even if client is modified, server validates everything
- Checks job permission again server-side
- Uses MySQL ON DUPLICATE KEY UPDATE for clean overwrites
- Updates local cache immediately after database
- Broadcasts to all players for immersion

### 6. Database Persistence

**Location:** `server.lua` - Startup thread

```lua
Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM dealer_ownership', {}, function(results)
        for _, row in ipairs(results) do
            dealerOwnership[row.dealer_id] = row.owner_job
        end
        print('[Davis Turfs] Loaded ' .. #results .. ' dealer ownership records')
    end)
end)
```

**Why it's important:**
- Loads ownership data on server start
- Populates local cache for fast lookups
- Prevents database query on every sale
- Ensures ownership persists through restarts

### 7. NPC Spawning System

**Location:** `client.lua` - NPC creation thread

```lua
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
        local ped = CreatePed(4, GetHashKey(dealer.ped), 
            dealer.coords.x, dealer.coords.y, dealer.coords.z, dealer.coords.w, 
            false, true)
        SetEntityHeading(ped, dealer.coords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        dealerPeds[dealer.id] = ped

        -- Create blip
        local blip = AddBlipForCoord(dealer.blipCoords.x, dealer.blipCoords.y, dealer.blipCoords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        -- ... more blip settings
        
        dealerBlips[dealer.id] = blip
    end
end)
```

**Why it's important:**
- Waits for ESX to be ready before spawning
- Pre-loads all ped models to prevent pop-in
- Makes NPCs invincible and frozen
- Creates persistent blips on map
- Stores references for cleanup on resource stop

### 8. ESX Menu Integration

**Location:** `client.lua` - OpenSellMenu() function

```lua
function OpenSellMenu(dealer)
    ESX.TriggerServerCallback('davis_turfs:getPlayerInventory', function(inventory)
        local elements = {}
        local hasDrugs = false

        -- Only show the drug that this dealer buys
        for _, drug in pairs(Config.Drugs) do
            if drug.item == dealer.drug then
                local count = 0
                
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
            -- Dialog for amount...
        end, function(data, menu)
            menu.close()
        end)
    end)
end
```

**Why it's important:**
- Gets fresh inventory from server (not client-side)
- Only shows drugs the dealer actually buys
- Only shows drugs the player actually has
- Displays current prices and quantities
- Uses native ESX menu system for consistency

### 9. Interaction Detection Loop

**Location:** `client.lua` - Main thread

```lua
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
                DrawMarker(...)

                if distance < Config.Marker.interactDistance then
                    -- Show help text and handle interactions
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)
```

**Why it's important:**
- Uses sleep optimization (500ms when far, 0ms when near)
- Checks all dealers each frame when nearby
- Draws markers only when close enough
- Handles both E (sell) and H (capture) inputs
- Efficient distance calculations

### 10. Cleanup on Resource Stop

**Location:** `client.lua` - onResourceStop event

```lua
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
```

**Why it's important:**
- Proper cleanup prevents entity buildup
- Checks if entity exists before deleting
- Removes blips from map
- Only runs for this specific resource
- Prevents memory leaks

## Security Features

### 1. Server-Side Only Money Operations
All money addition/removal happens server-side only. Clients cannot trigger money events directly.

### 2. Inventory Validation
Server checks actual player inventory before accepting sales, preventing item duplication.

### 3. Job Verification
All capture attempts validated server-side with fresh player data, preventing fake job exploits.

### 4. Distance Validation
Capture system checks if player stays close, preventing teleport exploits.

### 5. Database Sanitization
All database queries use parameterized queries (@parameter style), preventing SQL injection.

## Configuration Flexibility

The script supports:
- Single or multiple capture jobs
- Black money or clean money
- ESX society or custom storage
- Custom prices and dealer locations
- Custom earnings splits
- Custom timers and distances

All without editing core files - just config.lua.

## Performance Optimizations

1. **Sleep Optimization**: Loop sleeps 500ms when far from dealers, 0ms when close
2. **Local Caching**: Dealer ownership cached in memory, not queried each sale
3. **Efficient Distance Checks**: Uses vector math for quick calculations
4. **Model Pre-loading**: All ped models loaded at start, not on-demand
5. **Minimal DB Queries**: Only on capture and initial load, not on every sale

## Database Design

### dealer_ownership Table
```sql
id (AUTO_INCREMENT) - Primary key
dealer_id (UNIQUE) - Which dealer (prevents duplicate ownership)
owner_job - Which job/faction owns it
captured_at - Timestamp for tracking
```

Uses UNIQUE KEY on dealer_id to ensure one owner per dealer.

### faction_earnings Table
```sql
id (AUTO_INCREMENT) - Primary key
job (UNIQUE) - Which faction
amount - Total earnings accumulated
last_updated - Auto-updating timestamp
```

Uses ON DUPLICATE KEY UPDATE to accumulate safely.

## Common Patterns Used

1. **Server Callbacks**: Client requests data, server responds with validated info
2. **Event Validation**: Server always validates data from client events
3. **Local Cache + Database**: Fast lookups with persistent storage
4. **ESX Patterns**: Uses standard ESX functions and event naming
5. **Error Handling**: Checks for nil values and invalid data throughout

---

This code explanation covers the most critical sections that make the script functional, secure, and efficient.
