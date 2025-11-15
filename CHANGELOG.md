# Changelog

All notable changes to the Davis Turfs project will be documented in this file.

## [1.0.0] - 2024-11-15

### Added
- Initial release of Davis Turfs drug dealing system
- ESX menu integration for selling drugs
- Multiple configurable NPC drug dealers
- Territory control/capture system with timer
- Faction earnings distribution (85% player, 15% faction)
- Database persistence for dealer ownership
- Support for ESX society accounts
- Alternative database storage for faction earnings
- Server-side validation and exploit prevention
- Admin commands for managing dealers
- Configurable drug items and prices
- Configurable dealer locations and ped models
- Map blips for all dealer locations
- Interactive markers for dealer interaction
- Real-time notifications for players and factions
- Global broadcast when dealers are captured
- API exports for other scripts

### Features

#### Drug Selling System
- Sell drugs through ESX menu interface
- Each dealer only buys specific drug types
- Configurable prices per drug
- Choice between black money or clean money
- Server-side inventory validation

#### Territory Control
- 60-second capture timer (configurable)
- Job-based capture authorization
- Distance-based capture validation
- Movement cancellation if player moves away
- Database persistence across restarts

#### Faction Earnings
- Automatic 85/15 split (configurable)
- ESX society integration
- Alternative database storage option
- Real-time notifications to faction members

#### Security
- All transactions server-side validated
- Item existence checks
- Job permission checks
- Distance validations
- Exploit prevention measures

#### Admin Tools
- `/checkdealers` - View all dealer ownership
- `/resetdealer [id]` - Reset specific dealer ownership

### Technical Details
- Compatible with ESX Legacy and ESX 1.2+
- Requires mysql-async
- Requires esx_menu_default or esx_menu_dialog
- Optional esx_society for faction accounts
- Clean, commented code
- Comprehensive documentation
- Full installation guide
- Complete testing procedures

### Files Included
- `fxmanifest.lua` - Resource manifest
- `config.lua` - All configuration settings
- `client.lua` - Client-side logic
- `server.lua` - Server-side logic
- `dealers.sql` - Database schema
- `README.md` - Main documentation
- `INSTALLATION.md` - Installation guide
- `TESTING.md` - Testing procedures
- `.gitignore` - Git ignore rules

### Known Issues
None at release.

### Future Enhancements
Potential features for future versions:
- Dealer upgrade system
- Custom notification system
- Discord webhooks for captures
- Advanced statistics tracking
- Territory map overlay
- Conflict/war system between factions
- Cooldown timers for re-capture
- Dynamic pricing based on supply/demand

---

## Version History

**[1.0.0]** - Initial Release
