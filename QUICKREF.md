# Quick Reference - Davis Turfs

## Quick Start

### For Server Admins

1. **Install:**
   ```
   cd resources
   git clone [repo-url] davis-turfs
   ```

2. **Setup Database:**
   ```
   Run dealers.sql in your database
   ```

3. **Configure:**
   Edit `config.lua` - Set jobs, prices, locations

4. **Start:**
   Add to server.cfg: `ensure davis-turfs`

### For Players

**Selling Drugs:**
- Go to dealer (red blip on map)
- Press **E** to open menu
- Select drug and quantity
- Get paid!

**Capturing Dealers:**
- Be in authorized job (default: gang)
- Go to dealer
- Hold **H** for 60 seconds
- Your faction now earns 15% from sales here

## Commands

### Player Commands
None - all interactions are proximity-based

### Admin Commands
- `/checkdealers` - View dealer ownership
- `/resetdealer [id]` - Reset dealer ownership

## Configuration Quick Edit

### Change Capture Job
```lua
Config.CaptureJob = 'gang'  -- Single job
-- OR
Config.CaptureJob = {'gang', 'mafia'}  -- Multiple jobs
```

### Change Money Type
```lua
Config.MoneyType = 'black_money'  -- or 'money'
```

### Change Earnings Split
```lua
Config.PlayerCut = 85  -- Player gets 85%
Config.FactionCut = 15  -- Faction gets 15%
```

### Add Drug
```lua
{item = 'newdrug', price = 500, label = 'New Drug'}
```

### Add Dealer
```lua
{
    id = 5,
    coords = vector4(x, y, z, heading),
    blipCoords = vector3(x, y, z),
    ped = 'ped_model',
    drug = 'drugitem',
    defaultOwner = nil,
    name = 'Dealer Name'
}
```

## Default Settings

- **Capture Time:** 60 seconds
- **Capture Job:** gang
- **Player Cut:** 85%
- **Faction Cut:** 15%
- **Money Type:** black_money
- **Capture Distance:** 5 meters
- **Interaction Distance:** 2.5 meters

## Default Dealers

1. **Weed Dealer** - ID: 1, Drug: weed
2. **Cocaine Dealer** - ID: 2, Drug: coke
3. **Meth Dealer** - ID: 3, Drug: meth
4. **Opium Dealer** - ID: 4, Drug: opium

## Default Drugs & Prices

| Drug | Price | Label |
|------|-------|-------|
| weed | $150 | Weed |
| coke | $300 | Cocaine |
| meth | $400 | Methamphetamine |
| opium | $250 | Opium |

## Controls

- **E** - Open sell menu (when near dealer)
- **H (hold)** - Capture dealer (when authorized)
- **ESC** - Close menu

## Troubleshooting Quick Fixes

### Dealers Not Spawning
```
/restart davis-turfs
```

### Menu Not Opening
- Check you have drugs
- Make sure esx_menu_default is running
- Wait 5-10 seconds after spawning

### Can't Capture
- Check your job: `/myjob`
- Make sure job matches Config.CaptureJob
- Hold H, don't just press it

### No Earnings
- Check faction owns the dealer: `/checkdealers`
- Verify esx_society is running (if using societies)
- Check Config.UseSocietyAccount setting

## Database Queries

### Check Ownership
```sql
SELECT * FROM dealer_ownership;
```

### Check Faction Earnings
```sql
SELECT * FROM faction_earnings;
```

### Reset All Ownership
```sql
DELETE FROM dealer_ownership;
```

### Give Specific Ownership
```sql
INSERT INTO dealer_ownership (dealer_id, owner_job) 
VALUES (1, 'gang');
```

## File Structure
```
davis-turfs/
├── fxmanifest.lua      # Resource manifest
├── config.lua          # All settings
├── client.lua          # Client code
├── server.lua          # Server code
├── dealers.sql         # Database schema
├── README.md           # Full documentation
├── INSTALLATION.md     # Install guide
├── TESTING.md          # Test procedures
└── CHANGELOG.md        # Version history
```

## Support Resources

- **Full Documentation:** README.md
- **Installation Guide:** INSTALLATION.md
- **Testing Guide:** TESTING.md
- **Change Log:** CHANGELOG.md

## Common Scenarios

### Scenario: Two Gangs Fighting for Territory
1. Gang A captures Dealer 1
2. Gang A earns 15% from all sales at Dealer 1
3. Gang B wants the dealer
4. Gang B member holds H for 60 seconds
5. Gang B captures dealer
6. Gang B now earns the 15%

### Scenario: Selling Drugs
1. Player has 10 weed
2. Goes to Weed Dealer
3. Presses E, selects Weed
4. Enters amount: 10
5. Gets paid: 10 × $150 × 85% = $1,275
6. If dealer owned: Owner gets 10 × $150 × 15% = $225

### Scenario: Admin Reset
1. Gang owns dealer causing issues
2. Admin runs `/checkdealers` to find ID
3. Admin runs `/resetdealer 1`
4. Dealer is now neutral
5. Any gang can capture it again

## Performance Tips

- Keep dealer count under 10 for best performance
- Adjust marker draw distance if needed
- Monitor with `/profile` command
- Check resource usage regularly

## Security Checklist

- [x] Server-side validation enabled
- [x] Inventory checks active
- [x] Job verification working
- [x] Distance validation active
- [x] Database properly secured
- [x] No client-side money handling

## Integration Examples

### Get Dealer Owner
```lua
local owner = exports['davis-turfs']:GetDealerOwnership(1)
print('Dealer 1 owned by: ' .. tostring(owner))
```

### Get All Ownership
```lua
local all = exports['davis-turfs']:GetAllDealerOwnership()
for dealerId, owner in pairs(all) do
    print('Dealer ' .. dealerId .. ' owned by ' .. owner)
end
```

---

**For detailed information, see README.md**
