# Installation Guide - Davis Turfs

## Prerequisites

Before installing Davis Turfs, ensure you have:

1. **FiveM Server** - A running FiveM server
2. **ESX Framework** - Latest version of ESX Legacy or ESX 1.2+
3. **MySQL/MariaDB** - Database server
4. **mysql-async** - Database connector resource

## Step-by-Step Installation

### 1. Download the Resource

Clone or download this repository to your server's resources folder:

```bash
cd resources
git clone https://github.com/yourusername/davis-turfs.git
```

Or manually copy the files into `resources/davis-turfs/`

### 2. Database Setup

#### Option A: Using HeidiSQL/phpMyAdmin
1. Open your database management tool
2. Select your FiveM database
3. Go to the SQL tab
4. Copy and paste the contents of `dealers.sql`
5. Execute the SQL commands

#### Option B: Using Command Line
```bash
mysql -u your_username -p your_database < dealers.sql
```

#### Verify Database Tables
After running the SQL, verify these tables exist:
- `dealer_ownership` - Stores which faction owns which dealer
- `faction_earnings` - (Optional) Stores faction earnings if not using societies

### 3. Configure the Resource

Edit `config.lua` to customize the script for your server:

#### Essential Configuration

```lua
-- Set money type (black_money recommended for roleplay servers)
Config.MoneyType = 'black_money'  -- or 'money'

-- Set which job can capture dealers
Config.CaptureJob = 'gang'  -- Change to your gang/mafia job name
-- Or use multiple jobs:
-- Config.CaptureJob = {'gang', 'mafia', 'cartel'}

-- Decide on faction earnings storage
Config.UseSocietyAccount = true  -- Set to false if not using esx_society
```

#### Configure Dealers

1. **Choose Locations**: Decide where dealers will spawn
2. **Get Coordinates**: Use `/coords` or stand at location and use F8 console `getpos`
3. **Update Config**: Edit `Config.Dealers` with your coordinates

Example:
```lua
{
    id = 1,  -- Unique ID
    coords = vector4(85.34, -1959.49, 20.13, 318.71),  -- x, y, z, heading
    blipCoords = vector3(85.34, -1959.49, 20.13),
    ped = 'g_m_m_mexboss_01',  -- NPC model
    drug = 'weed',  -- Must match drug item
    defaultOwner = nil,  -- Leave nil
    name = 'Weed Dealer'
}
```

#### Configure Drugs

Add or modify drug types in `Config.Drugs`:

```lua
{item = 'weed', price = 150, label = 'Weed'},
{item = 'coke', price = 300, label = 'Cocaine'},
```

**Important**: Drug items must exist in your `items` database table!

### 4. Add to server.cfg

Add this line to your `server.cfg`:

```cfg
ensure davis-turfs
```

Place it after ESX and before any dependent resources:

```cfg
ensure es_extended
ensure mysql-async
ensure esx_menu_default
ensure davis-turfs
# ... other resources
```

### 5. Verify Dependencies

Make sure these resources are running:

**Required:**
- `es_extended`
- `mysql-async`
- `esx_menu_default` or `esx_menu_dialog`

**Optional (for society features):**
- `esx_society` or `esx_addonaccount`

Check with `/ensure resourcename` or review server console on start.

### 6. Start the Server

Restart your server or start the resource:

```
/restart davis-turfs
```

Or:

```
/ensure davis-turfs
```

### 7. Verify Installation

#### Check Console
Look for this message in server console:
```
[Davis Turfs] Loaded X dealer ownership records
```

#### In-Game Checks

1. **Spawn dealers**: Look for red blips on the map
2. **Test interaction**: Go to a dealer, you should see a red marker
3. **Test selling**: Press E with drugs in inventory
4. **Test capture**: Hold H with the correct job

### 8. Grant Admin Permissions

To use admin commands, ensure your admin group has permissions. 

For ESX:
```sql
-- Check your ace permissions or ESX groups
```

## Common Issues & Solutions

### Issue: Dealers Not Spawning

**Solutions:**
- Check ped model names are correct
- Verify coordinates are valid
- Check F8 console for errors
- Ensure resource started correctly (`/restart davis-turfs`)

### Issue: Menu Not Opening

**Solutions:**
- Verify `esx_menu_default` is running
- Check you have drugs in inventory
- Ensure ESX is initialized (wait a few seconds after spawn)
- Check F8 console for JavaScript errors

### Issue: Can't Capture Dealers

**Solutions:**
- Verify your job name matches `Config.CaptureJob`
- Check you're holding H (not just pressing)
- Stay within 5 meters during capture
- Check database connection is working

### Issue: No Faction Earnings

**Solutions:**
- If using societies: ensure `esx_society` is running
- Verify society account exists: `/checkaccount society_gangname`
- Check `Config.UseSocietyAccount` setting
- Review server console for database errors

### Issue: Players Can't Sell Drugs

**Solutions:**
- Verify drug items exist in database `items` table
- Check item names match exactly (case-sensitive)
- Ensure dealer drug type matches drug being sold
- Check server console for validation errors

## Testing Checklist

After installation, test these features:

- [ ] Dealers spawn at configured locations
- [ ] Blips appear on map
- [ ] Markers are visible near dealers
- [ ] Sell menu opens when pressing E
- [ ] Can sell drugs and receive money
- [ ] Capture starts when holding H
- [ ] Capture completes after timer
- [ ] Ownership saved to database
- [ ] Faction members receive earnings notification
- [ ] Admin commands work (`/checkdealers`, `/resetdealer`)

## Server Performance

### Recommended Settings

For optimal performance:
- **Players**: Works with 32-128 players
- **Dealers**: 4-10 dealers recommended
- **Marker Draw Distance**: 10.0 (default)
- **Update Interval**: 500ms (default)

### Resource Usage

Typical resource usage:
- **CPU**: <0.5% (with 5 dealers)
- **Memory**: ~2MB
- **Database**: Minimal (only on capture/sell)

## Updating the Script

To update:

1. Backup your `config.lua`
2. Download new version
3. Replace all files except `config.lua`
4. Compare new config with backup
5. Run any new SQL migrations if provided
6. Restart resource

## Security Checklist

Ensure these security measures are in place:

- [ ] Server-side validation enabled (default)
- [ ] Database tables created properly
- [ ] Admin commands restricted to admins
- [ ] ESX framework up to date
- [ ] mysql-async properly configured
- [ ] No client-side money giving

## Getting Help

If you encounter issues:

1. Check F8 console for errors
2. Review server console logs
3. Verify all dependencies are running
4. Check database connection
5. Review this installation guide
6. Create an issue on GitHub with:
   - Error messages
   - Server console logs
   - ESX version
   - Config settings (redact sensitive info)

## Next Steps

After successful installation:

1. Configure dealer locations for your map
2. Adjust drug prices for server economy
3. Set up faction jobs if not already done
4. Test all features thoroughly
5. Train your staff on the system
6. Announce to players

## Advanced Configuration

### Multiple Capture Jobs

Allow multiple jobs to capture:

```lua
Config.CaptureJob = {'gang', 'mafia', 'cartel', 'ballas'}
```

### Custom Money Distribution

Change the earnings split:

```lua
Config.PlayerCut = 90  -- Player gets 90%
Config.FactionCut = 10 -- Faction gets 10%
```

### Different Money Types Per Drug

This requires modifying `server.lua` - advanced users only.

### Integration with Other Scripts

The script exports functions for integration:

```lua
local owner = exports['davis-turfs']:GetDealerOwnership(dealerId)
local allOwnership = exports['davis-turfs']:GetAllDealerOwnership()
```

## Support

For support and updates:
- GitHub Issues
- FiveM Forums
- Discord Server (if applicable)

---

**Congratulations! Davis Turfs is now installed and ready to use.**
