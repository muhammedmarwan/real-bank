fx_version 'cerulean'
game 'gta5'
author 'oph3z'
description 'Advanced bank system | Made by codeReal'

ui_page {
    'html/index.html',
}

files {
    'html/index.html',
    'html/app.js',
    'html/style.css',
    'html/img/*.png',
    'html/img/*.jpg',
    'html/fonts/*.otf',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'GetFrameworkObject.lua',
}

client_scripts {
    'config/config_client.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/config_server.lua',
    'server/*.lua',
}

escrow_ignore {
    'config/*.lua',
    'GetFrameworkObject.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}

lua54 'yes'
