fx_version 'cerulean'
game 'gta5'

author 'Davis Turfs Script'
description 'ESX Drug Dealing and Territory Control System'
version '1.0.0'

shared_scripts {
    '@es_extended/locale.lua',
    'config.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'es_extended',
    'mysql-async'
}
