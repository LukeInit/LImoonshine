fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'LIMOONSHINE - Moonshine Distillery System'
version '1.0.0'
lua54 'yes'

shared_scripts {
	'@qbr-core/shared/locale.lua',
	'locale/en.lua',
	'config.lua'
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}