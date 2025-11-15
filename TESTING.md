# Testing Guide - Davis Turfs

This document provides comprehensive testing procedures for the Davis Turfs drug dealing system.

## Pre-Testing Setup

### 1. Server Configuration
- Ensure ESX framework is running
- Verify mysql-async is connected
- Check esx_menu_default is loaded
- (Optional) Verify esx_society for faction earnings

### 2. Database Verification
Run this SQL to verify tables exist:
```sql
SHOW TABLES LIKE 'dealer_ownership';
SHOW TABLES LIKE 'faction_earnings';
```

### 3. Test Items
Add test drugs to a player's inventory:
```sql
INSERT INTO items (name, label, weight) VALUES 
    ('weed', 'Weed', 1),
    ('coke', 'Cocaine', 1),
    ('meth', 'Methamphetamine', 1),
    ('opium', 'Opium', 1)
ON DUPLICATE KEY UPDATE name=name;
```

Give yourself test drugs:
```
/giveitem [your_id] weed 100
/giveitem [your_id] coke 100
```

### 4. Test Job
Set yourself to the capture job:
```
/setjob [your_id] gang 0
```

## Test Cases

### Test 1: Resource Loading
**Objective**: Verify the resource loads without errors

**Steps:**
1. Start/restart the server
2. Monitor server console
3. Check for Davis Turfs messages

**Expected Results:**
- No Lua errors in console
- Message: `[Davis Turfs] Loaded X dealer ownership records`
- Resource shows as "started" in `/status`

**Pass/Fail:** ______

---

### Test 2: NPC Spawning
**Objective**: Verify dealer NPCs spawn at configured locations

**Steps:**
1. Log into the server
2. Check the map for dealer blips
3. Navigate to each dealer location
4. Verify NPC is present and frozen

**Expected Results:**
- Red blips visible on map (default: 4 locations)
- NPCs spawned at exact coordinates
- NPCs are standing still (frozen)
- NPCs are invincible (shoot test)

**Pass/Fail:** ______

---

### Test 3: Marker Display
**Objective**: Verify interaction markers appear correctly

**Steps:**
1. Approach a dealer NPC
2. Observe from 15m away
3. Move to within 10m
4. Move to within 2m

**Expected Results:**
- No marker visible at 15m
- Red marker appears at ~10m
- Marker remains visible at 2m
- Help text appears at 2m: "Press E to sell drugs"

**Pass/Fail:** ______

---

### Test 4: Selling Drugs - Happy Path
**Objective**: Successfully sell drugs to appropriate dealer

**Steps:**
1. Give yourself weed: `/giveitem [id] weed 10`
2. Go to the Weed Dealer
3. Press E to open menu
4. Select Weed from menu
5. Enter amount: 5
6. Confirm sale

**Expected Results:**
- Menu opens showing Weed with quantity and price
- Dialog prompts for amount
- Success notification shows
- 5 weed removed from inventory
- Money added (black_money if configured)
- Sale amount = 5 * $150 * 85% = $637

**Pass/Fail:** ______

---

### Test 5: Selling Wrong Drug to Dealer
**Objective**: Verify dealers only buy their assigned drug

**Steps:**
1. Give yourself coke: `/giveitem [id] coke 10`
2. Go to the Weed Dealer (only buys weed)
3. Press E to open menu

**Expected Results:**
- Menu shows "You don't have any drugs to sell" OR
- Menu doesn't show cocaine as option
- No transaction occurs

**Pass/Fail:** ______

---

### Test 6: Selling Without Items
**Objective**: Prevent selling items player doesn't have

**Steps:**
1. Remove all drugs from inventory
2. Go to any dealer
3. Press E

**Expected Results:**
- Notification: "You don't have any drugs to sell"
- No menu opens OR menu is empty
- No money given

**Pass/Fail:** ______

---

### Test 7: Invalid Sale Amount
**Objective**: Prevent selling invalid quantities

**Steps:**
1. Give yourself weed: `/giveitem [id] weed 10`
2. Go to Weed Dealer
3. Press E, select Weed
4. Try to sell 0 items
5. Try to sell -5 items
6. Try to sell 100 items (more than you have)

**Expected Results:**
- 0 and negative amounts rejected
- Amount > inventory rejected
- Appropriate error messages shown
- No money given
- Inventory unchanged

**Pass/Fail:** ______

---

### Test 8: Capture Authorization - Correct Job
**Objective**: Allow authorized jobs to capture

**Steps:**
1. Set yourself to capture job: `/setjob [id] gang 0`
2. Go to any dealer
3. Hold H key for full capture time (60s)
4. Stay within 5 meters

**Expected Results:**
- Capture timer starts
- Progress notifications every second
- After 60s: "You have captured this dealer for your faction!"
- Database updated with ownership
- All players notified of capture

**Pass/Fail:** ______

---

### Test 9: Capture Authorization - Wrong Job
**Objective**: Prevent unauthorized jobs from capturing

**Steps:**
1. Set yourself to different job: `/setjob [id] police 0`
2. Go to any dealer
3. Hold H key

**Expected Results:**
- Notification: "You are not authorized to capture this dealer"
- No capture begins
- No database changes

**Pass/Fail:** ______

---

### Test 10: Capture - Movement Cancellation
**Objective**: Cancel capture if player moves away

**Steps:**
1. Set yourself to capture job: `/setjob [id] gang 0`
2. Go to dealer and hold H
3. After 10 seconds, move 10 meters away
4. Wait for timer to expire

**Expected Results:**
- Capture starts normally
- When moving >5m away: "Capture cancelled!"
- Capture stops
- No database changes
- No ownership change

**Pass/Fail:** ______

---

### Test 11: Capture - Already Owned
**Objective**: Prevent re-capturing owned dealer

**Steps:**
1. Capture a dealer (Test 8)
2. Immediately try to capture same dealer again
3. Hold H key

**Expected Results:**
- Notification: "This dealer is already owned by your faction"
- No capture begins
- No database changes

**Pass/Fail:** ______

---

### Test 12: Faction Earnings - With Society
**Objective**: Verify faction earnings with society accounts

**Prerequisites:**
- `Config.UseSocietyAccount = true`
- esx_society running
- Society account exists for gang

**Steps:**
1. Capture a dealer with gang job
2. Have another player sell drugs at that dealer
3. Check society account balance

**Expected Results:**
- Society account receives 15% of sale
- Online gang members get notification
- Message shows earnings amount
- Society balance increases

**Pass/Fail:** ______

---

### Test 13: Faction Earnings - Without Society
**Objective**: Verify faction earnings with database storage

**Prerequisites:**
- `Config.UseSocietyAccount = false`

**Steps:**
1. Capture a dealer with gang job
2. Have another player sell drugs at that dealer
3. Check faction_earnings table

**Expected Results:**
- Database entry created/updated for gang
- Amount = 15% of sale value
- Online gang members get notification

**Verification Query:**
```sql
SELECT * FROM faction_earnings WHERE job = 'gang';
```

**Pass/Fail:** ______

---

### Test 14: Money Distribution Accuracy
**Objective**: Verify correct money split

**Steps:**
1. Capture dealer as gang
2. Sell 10 weed at $150 each
3. Calculate expected amounts:
   - Total: 10 * $150 = $1,500
   - Player: $1,500 * 85% = $1,275
   - Faction: $1,500 * 15% = $225

**Expected Results:**
- Player receives exactly $1,275
- Faction receives exactly $225
- Correct money type (black_money or money)

**Pass/Fail:** ______

---

### Test 15: Database Persistence
**Objective**: Verify ownership persists after restart

**Steps:**
1. Capture a dealer as gang
2. Verify ownership: `/checkdealers`
3. Restart the resource: `/restart davis-turfs`
4. Check ownership again: `/checkdealers`

**Expected Results:**
- Before restart: dealer owned by gang
- After restart: dealer still owned by gang
- Database query confirms:
```sql
SELECT * FROM dealer_ownership;
```

**Pass/Fail:** ______

---

### Test 16: Admin Commands - Check Dealers
**Objective**: Verify admin can check ownership

**Prerequisites:**
- Admin permissions

**Steps:**
1. Run `/checkdealers`

**Expected Results:**
- Notification for each dealer
- Shows dealer name and owner
- "Unknown" or null for uncaptured dealers

**Pass/Fail:** ______

---

### Test 17: Admin Commands - Reset Dealer
**Objective**: Verify admin can reset ownership

**Prerequisites:**
- Admin permissions
- At least one captured dealer

**Steps:**
1. Note dealer ID from `/checkdealers`
2. Run `/resetdealer [dealer_id]`
3. Verify with `/checkdealers`

**Expected Results:**
- Success notification
- Dealer ownership removed
- Database confirms deletion:
```sql
SELECT * FROM dealer_ownership WHERE dealer_id = [dealer_id];
```

**Pass/Fail:** ______

---

### Test 18: Multiple Dealers
**Objective**: Verify multiple dealers work independently

**Steps:**
1. Sell drugs at Dealer 1 (Weed)
2. Sell drugs at Dealer 2 (Coke)
3. Capture Dealer 1 as gang
4. Capture Dealer 3 as different faction
5. Sell at both dealers

**Expected Results:**
- Each dealer only buys their drug
- Each capture is independent
- Earnings go to correct factions
- No cross-contamination of data

**Pass/Fail:** ______

---

### Test 19: Concurrent Players
**Objective**: Handle multiple players simultaneously

**Steps:**
1. Have 2+ players at same dealer
2. Both try to sell at same time
3. Both try to capture at same time

**Expected Results:**
- Both can sell without issues
- Only one capture succeeds
- No race conditions
- No money duplication
- Database handles concurrent updates

**Pass/Fail:** ______

---

### Test 20: Server Performance
**Objective**: Verify acceptable performance

**Tools:**
- `/profile` or F8 console
- Server resource monitor

**Steps:**
1. Join server with resource running
2. Monitor FPS and resource usage
3. Approach all dealers
4. Perform multiple sales
5. Check resource timing

**Expected Results:**
- Client FPS: No significant drop
- Server ms: <0.5ms average
- Memory: <5MB
- No performance warnings

**Pass/Fail:** ______

---

## Security Tests

### Test 21: Exploit Prevention - Item Duplication
**Objective**: Prevent selling items without having them

**Steps:**
1. Modify client-side code to try sending fake amounts
2. Try to trigger sale without items

**Expected Results:**
- Server validates inventory
- Transaction rejected
- No money given
- Console shows validation error

**Pass/Fail:** ______

---

### Test 22: Exploit Prevention - Money Manipulation
**Objective**: Prevent client-side money manipulation

**Steps:**
1. Try to capture dealer from far away
2. Try to trigger sale server event directly

**Expected Results:**
- All money handled server-side only
- Distance checks prevent remote capture
- Server validates all transactions

**Pass/Fail:** ______

---

## Edge Cases

### Test 23: Offline Faction Earnings
**Objective**: Earnings still work when faction offline

**Steps:**
1. Capture dealer as gang
2. Log out all gang members
3. Have another player sell at dealer

**Expected Results:**
- Sale completes normally
- Faction earnings recorded
- No errors from missing players

**Pass/Fail:** ______

---

### Test 24: Dealer at Maximum Distance
**Objective**: Verify distance checks work

**Steps:**
1. Stand exactly 2.5m from dealer
2. Try to interact
3. Move to 3.0m
4. Try to interact

**Expected Results:**
- 2.5m: interaction works
- 3.0m: no interaction possible
- Consistent behavior

**Pass/Fail:** ______

---

## Test Summary

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Resource Loading | | |
| 2 | NPC Spawning | | |
| 3 | Marker Display | | |
| 4 | Selling Drugs | | |
| 5 | Wrong Drug | | |
| 6 | No Items | | |
| 7 | Invalid Amount | | |
| 8 | Capture - Authorized | | |
| 9 | Capture - Unauthorized | | |
| 10 | Capture - Movement | | |
| 11 | Capture - Already Owned | | |
| 12 | Faction Earnings - Society | | |
| 13 | Faction Earnings - Database | | |
| 14 | Money Distribution | | |
| 15 | Database Persistence | | |
| 16 | Admin - Check | | |
| 17 | Admin - Reset | | |
| 18 | Multiple Dealers | | |
| 19 | Concurrent Players | | |
| 20 | Performance | | |
| 21 | Exploit - Duplication | | |
| 22 | Exploit - Money | | |
| 23 | Offline Earnings | | |
| 24 | Distance Checks | | |

**Total Passed:** _____ / 24
**Total Failed:** _____ / 24

## Test Environment

- **Server**: _____________
- **ESX Version**: _____________
- **Date**: _____________
- **Tester**: _____________

## Issues Found

| Issue # | Description | Severity | Status |
|---------|-------------|----------|--------|
| | | | |

## Notes

_Additional testing notes and observations:_

---

**Testing Complete:** [ ] Yes [ ] No
**Ready for Production:** [ ] Yes [ ] No
