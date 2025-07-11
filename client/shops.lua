CreateThread(function()
    -- Blip
    local blip = AddBlipForCoord(Config.GymPedCoords.xyz)
    SetBlipSprite(blip, 311) -- Dumbbell icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Gym")
    EndTextCommandSetBlipName(blip)

    -- Ped
    lib.requestModel(Config.GymPedModel)
    local ped = CreatePed(0, Config.GymPedModel, Config.GymPedCoords.x, Config.GymPedCoords.y, Config.GymPedCoords.z - 1.0, Config.GymPedCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Target Zone
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = 'fas fa-id-card',
                label = 'Buy Gym Pass',
                action = function()
                    lib.registerContext({
                        id = 'gym_pass_menu',
                        title = 'Gym Membership',
                        options = {
                            {
                                title = 'Buy Gym Pass - $' .. Config.GymPassPrice,
                                icon = 'fas fa-money-bill',
                                onSelect = function()
                                    TriggerServerEvent('qb-gym:buyPass')
                                end
                            }
                        }
                    })
                    lib.showContext('gym_pass_menu')
                end
            }
        },
        distance = 2.0
    })
end)
