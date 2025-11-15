# Troubleshooting Guide - Davis Turfs

Common issues and their solutions for the Davis Turfs drug dealing system.

## Installation Issues

### Issue: Resource Won't Start

**Symptoms:**
- Error: "Failed to start resource davis-turfs"
- Resource shows as "stopped" in `/resources`

**Solutions:**
1. Check fxmanifest.lua syntax:
   ```bash
   # Look for syntax errors in server console
   ```

2. Verify dependencies are running:
   ```
   /ensure es_extended
   /ensure mysql-async
   ```

3. Check file permissions:
   ```bash
   chmod -R 755 resources/davis-turfs/
   ```

4. Verify resource name matches folder name exactly

---

### Issue: Database Tables Not Created

**Symptoms:**
- Error: "Table 'dealer_ownership' doesn't exist"
- Script starts but captures don't work

**Solutions:**
1. Run the SQL file:
   ```sql
   -- Execute dealers.sql in your database
   -- Make sure you're using the correct database
   ```

2. Verify tables exist:
   ```sql
   SHOW TABLES LIKE 'dealer_%';
   ```

3. Check MySQL user has CREATE permissions

4. Verify database name in connection string

---

## Runtime Issues

### Issue: Dealers Not Spawning

**Symptoms:**
- No blips on map
- No NPCs at dealer locations
- No markers visible

**Solutions:**

1. **Check ESX is loaded:**
   ```lua
   -- F8 console:
   ExecuteCommand('status')
   -- Look for es_extended
   ```

2. **Verify ped models are valid:**
   - Open config.lua
   - Check each `ped` value
   - Use valid GTA 5 ped names
   - Test with default peds: `'a_m_m_business_01'`

3. **Check coordinates:**
   ```lua
   -- Stand at location, F8 console:
   getpos
   -- Compare with config.lua coordinates
   ```

4. **Restart resource:**
   ```
   /restart davis-turfs
   ```

5. **Check client console (F8):**
   - Look for Lua errors
   - Check for model loading issues

---

### Issue: Menu Won't Open

**Symptoms:**
- Press E, nothing happens
- No menu appears
- No error messages

**Solutions:**

1. **Check you have drugs:**
   ```
   /giveitem [id] weed 10
   ```

2. **Verify menu resource is running:**
   ```
   /ensure esx_menu_default
   ```
   Or:
   ```
   /ensure esx_menu_dialog
   ```

3. **Check you're at the RIGHT dealer:**
   - Weed dealer only buys weed
   - Coke dealer only buys coke
   - Check config.lua for dealer.drug values

4. **Wait after spawning:**
   - ESX needs 5-10 seconds to initialize
   - Try again after waiting

5. **Check F8 console for errors:**
   - JavaScript errors indicate menu issues
   - Lua errors indicate script issues

6. **Test menu system:**
   ```
   -- Try another ESX menu to verify system works
   /openphone (or any ESX menu command)
   ```

---

### Issue: Can't Sell Drugs

**Symptoms:**
- Menu opens but is empty
- "You don't have any drugs to sell"
- Transaction doesn't complete

**Solutions:**

1. **Verify drug items exist in database:**
   ```sql
   SELECT * FROM items WHERE name IN ('weed', 'coke', 'meth', 'opium');
   ```
   If not found, add them:
   ```sql
   INSERT INTO items (name, label, weight) VALUES 
       ('weed', 'Weed', 1),
       ('coke', 'Cocaine', 1);
   ```

2. **Check item names match exactly:**
   - Config.Drugs item names
   - Database item names
   - Case-sensitive!

3. **Verify you have the items:**
   ```
   /inventory
   -- Check for the drug items
   ```

4. **Give yourself test items:**
   ```
   /giveitem [your_id] weed 50
   ```

5. **Check server console:**
   - Look for validation errors
   - Check for database errors

6. **Verify dealer drug type:**
   ```lua
   -- In config.lua:
   -- If dealer.drug = 'weed'
   -- You must sell weed at this dealer
   ```

---

### Issue: Capture System Not Working

**Symptoms:**
- Hold H, nothing happens
- "Not authorized" message
- Capture doesn't start

**Solutions:**

1. **Check your job:**
   ```
   /myjob
   -- Should match Config.CaptureJob
   ```

2. **Set correct job:**
   ```
   /setjob [id] gang 0
   ```

3. **Verify Config.CaptureJob:**
   ```lua
   -- In config.lua:
   Config.CaptureJob = 'gang'
   -- OR for multiple:
   Config.CaptureJob = {'gang', 'mafia'}
   ```

4. **Check you're holding H, not pressing:**
   - HOLD the key for 60 seconds
   - Don't tap it

5. **Stay within range:**
   - Must stay within 5 meters of dealer
   - Don't move while capturing

6. **Check already owned:**
   ```
   /checkdealers
   -- See if your faction already owns it
   ```

---

### Issue: Capture Cancels Immediately

**Symptoms:**
- Capture starts then "Capture cancelled!" immediately
- Can't complete capture

**Solutions:**

1. **Don't move:**
   - Stay within 5 meters of start position
   - Don't run around while capturing

2. **Check for vehicle entry:**
   - Don't enter vehicles during capture
   - Don't teleport

3. **Disable other scripts:**
   - Some scripts may teleport player
   - Disable conflicting scripts temporarily

4. **Test distance:**
   ```lua
   -- Mark your position at start
   -- Check if you're moving unintentionally
   ```

---

### Issue: No Faction Earnings

**Symptoms:**
- Capture works but no earnings
- Faction members don't get notifications
- Society account not receiving money

**Solutions:**

1. **Check dealer is owned:**
   ```
   /checkdealers
   -- Verify faction owns the dealer
   ```

2. **If using societies:**
   ```
   /ensure esx_society
   /ensure esx_addonaccount
   ```

3. **Verify society account exists:**
   ```sql
   SELECT * FROM addon_account WHERE name = 'society_gang';
   ```
   Create if missing:
   ```sql
   INSERT INTO addon_account (name, label, shared) 
   VALUES ('society_gang', 'Gang', 1);
   ```

4. **Check config setting:**
   ```lua
   Config.UseSocietyAccount = true  -- For society
   Config.UseSocietyAccount = false -- For database
   ```

5. **If using database storage:**
   ```sql
   SELECT * FROM faction_earnings WHERE job = 'gang';
   -- Should show accumulated earnings
   ```

6. **Check server console:**
   - Look for errors during money transfer
   - Check ESX account errors

---

### Issue: Wrong Money Amount

**Symptoms:**
- Receive less money than expected
- Percentages seem wrong

**Solutions:**

1. **Understand the split:**
   ```
   Total = quantity × price
   Player gets: 85% of total
   Faction gets: 15% of total (if dealer owned)
   ```

2. **Example calculation:**
   ```
   Sell 10 weed at $150 each
   Total = 10 × $150 = $1,500
   Player = $1,500 × 85% = $1,275
   Faction = $1,500 × 15% = $225
   ```

3. **Check config:**
   ```lua
   Config.PlayerCut = 85
   Config.FactionCut = 15
   -- Should total 100
   ```

4. **Verify drug prices:**
   ```lua
   -- In config.lua Config.Drugs:
   {item = 'weed', price = 150}
   ```

---

### Issue: Getting Black Money Instead of Clean (or vice versa)

**Symptoms:**
- Expected money, got black_money
- Expected black_money, got money

**Solution:**

Check config setting:
```lua
Config.MoneyType = 'black_money'  -- For black money
Config.MoneyType = 'money'        -- For clean money
```

Restart after changing:
```
/restart davis-turfs
```

---

## Database Issues

### Issue: Ownership Not Persisting

**Symptoms:**
- Capture dealer, restart server, ownership lost
- Database not saving

**Solutions:**

1. **Check database connection:**
   ```
   # Server console should show:
   [mysql-async] [MySQL] Database connected
   ```

2. **Verify table exists:**
   ```sql
   DESCRIBE dealer_ownership;
   ```

3. **Check for database errors:**
   ```
   # Server console for SQL errors
   ```

4. **Manually check ownership:**
   ```sql
   SELECT * FROM dealer_ownership;
   ```

5. **Test manual insert:**
   ```sql
   INSERT INTO dealer_ownership (dealer_id, owner_job) 
   VALUES (1, 'gang');
   ```

---

### Issue: SQL Errors on Capture

**Symptoms:**
- Error: "Duplicate entry for key 'dealer_id'"
- Capture fails with database error

**Solutions:**

1. **Update SQL schema:**
   - The ON DUPLICATE KEY UPDATE should handle this
   - Verify SQL file was run correctly

2. **Check table structure:**
   ```sql
   SHOW CREATE TABLE dealer_ownership;
   ```
   Should have UNIQUE KEY on dealer_id

3. **Clean duplicate entries:**
   ```sql
   -- Find duplicates
   SELECT dealer_id, COUNT(*) 
   FROM dealer_ownership 
   GROUP BY dealer_id 
   HAVING COUNT(*) > 1;
   
   -- Remove duplicates, keep latest
   DELETE t1 FROM dealer_ownership t1
   INNER JOIN dealer_ownership t2 
   WHERE t1.id < t2.id 
   AND t1.dealer_id = t2.dealer_id;
   ```

---

## Performance Issues

### Issue: Low FPS Near Dealers

**Symptoms:**
- FPS drops when near dealers
- Game lags around dealer areas

**Solutions:**

1. **Reduce draw distance:**
   ```lua
   -- In config.lua:
   Config.Marker.drawDistance = 5.0  -- Reduce from 10.0
   ```

2. **Reduce marker size:**
   ```lua
   Config.Marker.size = {x = 1.0, y = 1.0, z = 0.5}
   ```

3. **Limit dealer count:**
   - Fewer dealers = better performance
   - 4-6 dealers recommended

4. **Check other scripts:**
   - Multiple marker scripts can conflict
   - /profile to see resource usage

---

### Issue: High Server Lag

**Symptoms:**
- Server ms increases
- Player desyncs

**Solutions:**

1. **Check database queries:**
   ```
   # Should only query on:
   # - Server start (load ownership)
   # - Capture (update ownership)
   # - Sale (update earnings if not using society)
   ```

2. **Optimize marker loop:**
   - Already optimized with sleep values
   - Should be minimal impact

3. **Check player count:**
   - Script tested for 32-128 players
   - Monitor with /profile

---

## Admin Issues

### Issue: Admin Commands Don't Work

**Symptoms:**
- /checkdealers does nothing
- /resetdealer shows "no permission"

**Solutions:**

1. **Verify admin permissions:**
   ```
   # Check your admin group has 'admin' permission
   ```

2. **Check ESX admin system:**
   ```lua
   -- Verify you have admin/superadmin group
   ```

3. **Test with console:**
   ```
   # Run from server console instead:
   resetdealer 1
   ```

---

## Integration Issues

### Issue: Conflicts with Other Scripts

**Symptoms:**
- Other drug scripts interfere
- Marker conflicts
- Menu conflicts

**Solutions:**

1. **Check for script conflicts:**
   - Multiple drug scripts may conflict
   - Choose one drug system

2. **Marker conflicts:**
   - Other scripts using same markers
   - Adjust Config.Marker settings

3. **Menu conflicts:**
   - Ensure only one ESX menu system
   - /ensure esx_menu_default only

---

## Debug Tools

### Enable Debug Mode

Add to top of client.lua:
```lua
local DEBUG = true
function DebugPrint(msg)
    if DEBUG then print('[Davis Turfs Debug] ' .. msg) end
end
```

### Check Active Dealers
```
/checkdealers
```

### Check Your Job
```
/myjob
```

### Give Test Items
```
/giveitem [id] weed 100
/giveitem [id] coke 100
```

### Force Job Change
```
/setjob [id] gang 0
```

### Check Database
```sql
-- Check ownership
SELECT * FROM dealer_ownership;

-- Check earnings
SELECT * FROM faction_earnings;

-- Check items
SELECT * FROM items WHERE name LIKE '%weed%';
```

---

## Getting Further Help

If issues persist:

1. **Check F8 console** for errors
2. **Check server console** for errors
3. **Enable debug mode** and check logs
4. **Test in clean environment** (disable other scripts)
5. **Verify all dependencies** are updated
6. **Check ESX version** (should be latest)

### Information to Provide When Asking for Help

- FiveM version
- ESX version
- Error messages (full text)
- Server console output
- F8 console output
- Config.lua (redact sensitive info)
- Steps to reproduce issue

---

## Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| "not enough drugs" | Insufficient items | Get more items or check inventory |
| "not authorized" | Wrong job | Change to correct job |
| "already owned" | Faction owns dealer | Capture different dealer |
| "no drugs to sell" | Empty inventory | Get drugs first |
| "Invalid amount" | Bad input | Enter valid number |
| "Table doesn't exist" | DB not set up | Run dealers.sql |

---

**Most issues are solved by:**
1. Checking server console
2. Checking F8 console
3. Verifying configuration
4. Ensuring dependencies are running
5. Restarting the resource
