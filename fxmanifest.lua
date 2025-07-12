fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Hexxr'
description 'QBCore Gym System with qb-target and ox_lib'

shared_script 'config.lua'

client_scripts {
  '@ox_lib/init.lua',
  'client/override.lua',
  'client/stat_effects.lua',
  'client/stats.lua',
  'client/workout.lua',
  'client/shops.lua',
  'client/ui.lua',
  'client/zones.lua',
  'client/testing.lua'
}

exports{
  'GetStatEffect',
  'ApplyStrengthEffect',
  'ApplyStaminaEffect'
}

server_script 'server/main.lua'

dependencies{
  'qb-core',
  'ox_lib',
  'qb-target'
}