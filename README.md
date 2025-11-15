# Davis Turfs - FiveM ESX Drug Dealing & Territory Control

A complete FiveM script for ESX that implements a drug dealing system with NPC dealers and faction territory control mechanics.

## Features

### 1. Drug Selling System
- **ESX Menu Integration**: Sell drugs through the native ESX menu system
- **Configurable Drug Items**: Define which items are sellable drugs in `config.lua`
- **Configurable Prices**: Set individual prices for each drug type
- **Money Type Selection**: Choose between black money or clean money for drug sales
- **Inventory Validation**: Server-side checks prevent exploits

### 2. NPC Drug Dealers
- **Multiple Dealer Locations**: Configure as many dealers as needed
- **Specialized Dealers**: Each dealer only buys specific drug types
- **Visual Markers**: Interact with dealers via ground markers
- **Map Blips**: All dealer locations are shown on the map
- **Persistent NPCs**: Dealers spawn automatically and are invincible

### 3. Territory Control System
- **Dealer Capture**: Factions can capture dealers to earn passive income
- **Capture Timer**: Configurable capture time (default 60 seconds)
- **Job Restriction**: Only specific jobs can capture dealers
- **Database Persistence**: Ownership persists through server restarts
- **Global Notifications**: All players are notified when a dealer is captured

### 4. Faction Earnings
- **Automatic Split**: 85% to seller, 15% to faction owner
- **Society Integration**: Money can go to ESX society accounts
- **Alternative Storage**: Custom database storage if not using societies
- **Real-time Notifications**: Faction members get notified of earnings

### 5. Security Features
- **Server-side Validation**: All transactions validated server-side
- **Item Checks**: Prevents selling items you don't have
- **Job Verification**: Capture permissions checked server-side
- **Exploit Prevention**: Amount and distance validations

## Installation

### 1. Database Setup
Execute the SQL file to create required tables:
```sql
-- Run dealers.sql in your database
```

### 2. Resource Installation
1. Copy the `davis-turfs` folder to your server's `resources` directory
2. Add to your `server.cfg`:
```cfg
ensure davis-turfs
```

### 3. Dependencies
Make sure you have these resources running:
- `es_extended` (ESX Framework)
- `mysql-async` (Database connector)
- `esx_menu_default` or `esx_menu_dialog` (for menus)

Optional:
- `esx_society` or `esx_addonaccount` (for faction society accounts)

## Configuration

### Config.lua Overview

#### General Settings
```lua
Config.MoneyType = 'black_money'  -- or 'money'
Config.CaptureTime = 60           -- seconds to capture
Config.CaptureJob = 'gang'        -- job required to capture
Config.PlayerCut = 85             -- player earnings %
Config.FactionCut = 15            -- faction earnings %
Config.UseSocietyAccount = true   -- use society or database
```

#### Drug Configuration
```lua
Config.Drugs = {
    {item = 'weed', price = 150, label = 'Weed'},
    {item = 'coke', price = 300, label = 'Cocaine'},
    -- Add more drugs here
}
```

#### Dealer Configuration
```lua
Config.Dealers = {
    {
        id = 1,
        coords = vector4(x, y, z, heading),
        blipCoords = vector3(x, y, z),
        ped = 'g_m_m_mexboss_01',
        drug = 'weed',  -- must match drug item
        defaultOwner = nil,
        name = 'Weed Dealer'
    },
    -- Add more dealers here
}
```

## Usage

### For Players

#### Selling Drugs
1. Approach any dealer NPC (look for the red marker)
2. Press **E** to open the sell menu
3. Select the drug type and quantity
4. Receive payment (85% of total value)

#### Capturing Dealers
1. Have the required job (configured in `Config.CaptureJob`)
2. Approach the dealer you want to capture
3. Hold **H** for the configured capture time (default 60s)
4. Stay within 5 meters during capture
5. Your faction now earns 15% from all sales at this dealer

### For Admins

#### Check Dealer Ownership
```
/checkdealers
```
Shows which faction owns each dealer.

#### Reset Dealer Ownership
```
/resetdealer [dealer_id]
```
Removes ownership from a specific dealer.

## Code Structure

### client.lua
- NPC and blip creation
- Marker drawing and interaction
- Menu handling
- Capture system UI
- Player notifications

### server.lua
- Database operations
- Transaction validation
- Money distribution
- Faction earnings management
- Admin commands
- Exploit prevention

### config.lua
- All configurable settings
- Dealer locations
- Drug definitions
- Job requirements
- UI settings

## Important Code Sections

### Server-side Validation
All drug sales are validated server-side to prevent exploits:
```lua
-- Check if player has the drugs
local playerItem = xPlayer.getInventoryItem(drugItem)
if not playerItem or playerItem.count < amount then
    xPlayer.showNotification(Config.Locale['not_enough_drugs'])
    return
end
```

### Earnings Distribution
Money is split between player and faction owner:
```lua
local playerEarnings = math.floor(totalPrice * (Config.PlayerCut / 100))
local factionEarnings = math.floor(totalPrice * (Config.FactionCut / 100))
```

### Capture Validation
Capture attempts are validated for job and ownership:
```lua
if dealerOwnership[dealerId] == xPlayer.job.name then
    TriggerClientEvent('davis_turfs:captureComplete', _source, false, Config.Locale['already_owned'])
    return
end
```

### Database Persistence
Dealer ownership is stored and loaded from MySQL:
```lua
MySQL.Async.execute('INSERT INTO dealer_ownership (dealer_id, owner_job) VALUES (@dealer_id, @owner_job) 
    ON DUPLICATE KEY UPDATE owner_job = @owner_job, captured_at = CURRENT_TIMESTAMP', {...})
```

## API Exports

### GetDealerOwnership
```lua
local owner = exports['davis-turfs']:GetDealerOwnership(dealerId)
```
Returns the job name that owns the specified dealer.

### GetAllDealerOwnership
```lua
local ownership = exports['davis-turfs']:GetAllDealerOwnership()
```
Returns a table of all dealer ownership data.

## Customization

### Adding New Drugs
1. Add the drug to `Config.Drugs`:
```lua
{item = 'heroin', price = 500, label = 'Heroin'}
```
2. Make sure the item exists in your ESX items database

### Adding New Dealers
1. Add a dealer to `Config.Dealers`:
```lua
{
    id = 5,
    coords = vector4(x, y, z, heading),
    blipCoords = vector3(x, y, z),
    ped = 'ped_model_name',
    drug = 'heroin',
    defaultOwner = nil,
    name = 'Heroin Dealer'
}
```

### Changing Capture Mechanics
Modify these settings in `config.lua`:
- `Config.CaptureTime` - How long to hold H
- `Config.CaptureJob` - Which job(s) can capture
- Distance check in `client.lua` (currently 5 meters)

### Customizing Earnings Split
Adjust in `config.lua`:
```lua
Config.PlayerCut = 85  -- Player gets 85%
Config.FactionCut = 15 -- Faction gets 15%
```

## Troubleshooting

### Dealers Not Spawning
- Check that ped models are valid
- Verify coordinates are correct
- Check F8 console for errors

### Menu Not Opening
- Ensure `esx_menu_default` or similar is running
- Check ESX is properly initialized
- Verify player has drugs to sell

### Capture Not Working
- Verify player has the correct job
- Check database connection
- Ensure dealer ID is correct

### No Faction Earnings
- If using societies, ensure `esx_society` is running
- Check society account exists for the job
- Verify `Config.UseSocietyAccount` setting

## License

This script is open source and free to use.

## Support

For issues or questions, please create an issue on the GitHub repository.

## Credits

Created for the Davis Turfs FiveM server.