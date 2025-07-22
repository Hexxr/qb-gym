fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Hexxr'
description 'QBCore Gym System with qb-target and ox_lib'
version '2.0.0'

shared_scripts{
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
  'client/override.lua',
  'client/stat_effects.lua',
  'client/stats.lua',
  'client/workout.lua',
  'client/shops.lua',
  'client/ui.lua',
  'client/zones.lua',
  --'client/testing.lua'-- uncomment for adding new workout locations/fine-tuning
}

exports{
  'GetStatEffect',
  'ApplyStrengthEffect',
  'ApplyStaminaEffect'
}

server_scripts{
  'server/main.lua'
}

dependencies{
  'oxmysql',
  'qb-core',
  'ox_lib',
  'qb-target'
}