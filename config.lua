Config = {}

-- Language settings
Config.Locale = 'en'

-- Money type for drug sales (can be 'black_money' or 'money')
Config.MoneyType = 'black_money'

-- Capture settings
Config.CaptureTime = 60 -- Time in seconds to capture a dealer
Config.CaptureJob = 'gang' -- Job required to capture dealers (can be a table for multiple jobs)

-- Earnings distribution
Config.PlayerCut = 85 -- Percentage that goes to the player
Config.FactionCut = 15 -- Percentage that goes to the faction

-- Whether to use ESX society accounts for faction earnings
-- If true, money goes to society account (requires esx_society or similar)
-- If false, money is stored in database (custom storage)
Config.UseSocietyAccount = true

-- Sellable drugs configuration
-- Each drug has: item name, base price, and label
Config.Drugs = {
    {item = 'weed', price = 150, label = 'Weed'},
    {item = 'coke', price = 300, label = 'Cocaine'},
    {item = 'meth', price = 400, label = 'Methamphetamine'},
    {item = 'opium', price = 250, label = 'Opium'}
}

-- NPC Dealer locations and configuration
-- Each dealer has:
-- id: unique identifier
-- coords: spawn location (x, y, z, heading)
-- blipCoords: blip location on map
-- ped: ped model
-- drug: which drug this dealer buys (must match Config.Drugs item name)
-- defaultOwner: default faction that owns this dealer (nil for no owner)
Config.Dealers = {
    {
        id = 1,
        coords = vector4(85.34, -1959.49, 20.13, 318.71),
        blipCoords = vector3(85.34, -1959.49, 20.13),
        ped = 'g_m_m_mexboss_01',
        drug = 'weed',
        defaultOwner = nil,
        name = 'Weed Dealer'
    },
    {
        id = 2,
        coords = vector4(1211.74, -1389.46, 35.22, 87.24),
        blipCoords = vector3(1211.74, -1389.46, 35.22),
        ped = 'g_m_m_chemwork_01',
        drug = 'coke',
        defaultOwner = nil,
        name = 'Cocaine Dealer'
    },
    {
        id = 3,
        coords = vector4(-1174.53, -1573.54, 4.35, 213.73),
        blipCoords = vector3(-1174.53, -1573.54, 4.35),
        ped = 'g_m_m_chigoon_01',
        drug = 'meth',
        defaultOwner = nil,
        name = 'Meth Dealer'
    },
    {
        id = 4,
        coords = vector4(90.82, -1979.33, 20.42, 318.20),
        blipCoords = vector3(90.82, -1979.33, 20.42),
        ped = 'g_m_m_mexboss_02',
        drug = 'opium',
        defaultOwner = nil,
        name = 'Opium Dealer'
    }
}

-- Blip settings
Config.Blip = {
    sprite = 501, -- Drug icon
    color = 1, -- Red
    scale = 0.8,
    display = 4
}

-- Marker settings for interaction
Config.Marker = {
    type = 1,
    size = {x = 1.5, y = 1.5, z = 1.0},
    color = {r = 255, g = 0, b = 0, a = 100},
    drawDistance = 10.0,
    interactDistance = 2.5
}

-- Notification messages
Config.Locale = {
    ['press_e_sell'] = 'Press ~INPUT_CONTEXT~ to sell drugs',
    ['press_e_capture'] = 'Press ~INPUT_CONTEXT~ to capture dealer',
    ['not_enough_drugs'] = 'You don\'t have enough drugs to sell',
    ['sold_drugs'] = 'You sold %sx %s for $%s',
    ['no_drugs'] = 'You don\'t have any drugs to sell',
    ['capturing'] = 'Capturing dealer... %s seconds remaining',
    ['capture_complete'] = 'You have captured this dealer for your faction!',
    ['capture_cancelled'] = 'Capture cancelled!',
    ['already_owned'] = 'This dealer is already owned by your faction',
    ['not_authorized'] = 'You are not authorized to capture this dealer',
    ['dealer_captured'] = 'A dealer has been captured by %s!',
    ['earnings_received'] = 'Your faction earned $%s from drug sales'
}
