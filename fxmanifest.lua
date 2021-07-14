games { 'gta5' }
fx_version 'cerulean'

shared_script 'config.lua'

server_scripts { 
	'@mysql-async/lib/MySQL.lua', 

	'server/main.lua',
	'server/commands.lua',
	'server/classes/**/*.lua',
}

client_scripts {  
	'client/main.lua'
}

exports {
	'IsInArena'
}
