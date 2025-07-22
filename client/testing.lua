-- Add this temporarily to your client script to help position the treadmill coordinates

local testingTreadmill = false
local treadmillPos = nil

RegisterCommand('treadmillpos', function()
    testingTreadmill = not testingTreadmill
    if testingTreadmill then
        lib.notify({ type = 'info', description = 'Treadmill positioning mode ON. Use arrow keys to adjust.' })

        local ped = PlayerPedId()
        treadmillPos = GetEntityCoords(ped)

        -- Start the animation
        lib.playAnim(ped, 'amb@world_human_jog_standing@male@base', 'base', 8.0, -8.0, -1, 1, 0.0, false, 0, false)

        CreateThread(function()
            while testingTreadmill do
                local heading = GetEntityHeading(ped)

                -- Display current position
                lib.showTextUI(string.format(
                    '[Treadmill Positioning Mode]  \n' ..
                    'Coords: vector3(%.2f, %.2f, %.2f)  \n' ..
                    'Heading: %.2f  \n' ..
                    '[W/S] Forward/Back | [A/D] Left/Right  \n' ..
                    '[Page Up/Down] Height | [Q/E] Rotate  \n' ..
                    '[ENTER] Copy to clipboard  \n' ..
                    '[X] or [/treadmillpos] to EXIT',
                    treadmillPos.x, treadmillPos.y, treadmillPos.z, heading
                ))

                -- Exit on X key
                if IsControlJustPressed(0, 73) then -- X key
                    testingTreadmill = false
                end

                -- Movement controls using WASD
                if IsControlPressed(0, 32) then -- W
                    treadmillPos = treadmillPos + GetEntityForwardVector(ped) * 0.01
                end
                if IsControlPressed(0, 33) then -- S
                    treadmillPos = treadmillPos - GetEntityForwardVector(ped) * 0.01
                end
                if IsControlPressed(0, 34) then -- A (strafe left)
                    local forward = GetEntityForwardVector(ped)
                    local right = vector3(forward.y, -forward.x, 0.0)
                    treadmillPos = treadmillPos - right * 0.01
                end
                if IsControlPressed(0, 35) then -- D (strafe right)
                    local forward = GetEntityForwardVector(ped)
                    local right = vector3(forward.y, -forward.x, 0.0)
                    treadmillPos = treadmillPos + right * 0.01
                end

                -- Height controls
                if IsControlPressed(0, 10) then -- Page Up
                    treadmillPos = vector3(treadmillPos.x, treadmillPos.y, treadmillPos.z + 0.01)
                end
                if IsControlPressed(0, 11) then -- Page Down
                    treadmillPos = vector3(treadmillPos.x, treadmillPos.y, treadmillPos.z - 0.01)
                end

                -- Rotation controls
                if IsControlPressed(0, 44) then -- Q
                    SetEntityHeading(ped, heading - 1.0)
                end
                if IsControlPressed(0, 38) then -- E
                    SetEntityHeading(ped, heading + 1.0)
                end

                -- Copy to clipboard
                if IsControlJustPressed(0, 191) then -- Enter
                    local copyText = string.format(
                        "treadmillCoords = vector3(%.2f, %.2f, %.2f), -- Where player stands on treadmill\n" ..
                        "treadmillHeading = %.1f, -- Direction to face",
                        treadmillPos.x, treadmillPos.y, treadmillPos.z, GetEntityHeading(ped)
                    )
                    lib.setClipboard(copyText)
                    lib.notify({ type = 'success', description = 'Coordinates copied to clipboard!' })
                end

                -- Apply position
                SetEntityCoords(ped, treadmillPos.x, treadmillPos.y, treadmillPos.z, false, false, false, false)

                Wait(0)
            end
        end)
    else
        lib.hideTextUI()
        ClearPedTasks(PlayerPedId())
        lib.notify({ type = 'info', description = 'Treadmill positioning mode OFF' })
    end
end, false)

-- Command to test the exact position from config
RegisterCommand('testtreadmillconfig', function(source, args)
    local treadmillNum = tonumber(args[1]) or 1
    local treadmill = Config.Treadmills['treadmill' .. treadmillNum]

    if treadmill and treadmill.treadmillCoords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, treadmill.treadmillCoords.x, treadmill.treadmillCoords.y, treadmill.treadmillCoords.z, false, false, false, false)
        SetEntityHeading(ped, treadmill.treadmillHeading or 0.0)
        lib.playAnim(ped, treadmill.animDict, treadmill.anim, 8.0, -8.0, -1, 1, 0.0, false, 0, false)
        lib.notify({ type = 'info', description = 'Testing treadmill ' .. treadmillNum .. ' position' })
    else
        lib.notify({ type = 'error', description = 'Treadmill config not found' })
    end
end, false)

local testingChinup = false
local chinupPos = nil

RegisterCommand('chinuppos', function()
    testingChinup = not testingChinup
    if testingChinup then
        lib.notify({ type = 'info', description = 'Chin-up positioning mode ON. Position yourself under the bar.' })

        local ped = PlayerPedId()
        chinupPos = GetEntityCoords(ped)

        -- Start the chin-up animation
        lib.playAnim(ped, 'amb@prop_human_muscle_chin_ups@male@base', 'base', 8.0, -8.0, -1, 1, 0.0, false, 0, false)

        CreateThread(function()
            while testingChinup do
                local heading = GetEntityHeading(ped)

                -- Display current position
                lib.showTextUI(string.format(
                    '[Chin-up Positioning Mode]  \n' ..
                    'Coords: vector3(%.2f, %.2f, %.2f)  \n' ..
                    'Heading: %.2f  \n' ..
                    '[W/S] Forward/Back | [A/D] Left/Right  \n' ..
                    '[Page Up/Down] Height | [Q/E] Rotate  \n' ..
                    '[SHIFT] Slow Movement | [CTRL] Fast Movement  \n' ..
                    '[ENTER] Copy to clipboard  \n' ..
                    '[X] or [/chinuppos] to EXIT',
                    chinupPos.x, chinupPos.y, chinupPos.z, heading
                ))

                -- Exit on X key
                if IsControlJustPressed(0, 73) then -- X key
                    testingChinup = false
                end

                -- Movement speed modifier
                local moveSpeed = 0.01
                if IsControlPressed(0, 21) then -- Shift for slow
                    moveSpeed = 0.005
                elseif IsControlPressed(0, 36) then -- Ctrl for fast
                    moveSpeed = 0.02
                end

                -- Movement controls using WASD
                if IsControlPressed(0, 32) then -- W
                    chinupPos = chinupPos + GetEntityForwardVector(ped) * moveSpeed
                end
                if IsControlPressed(0, 33) then -- S
                    chinupPos = chinupPos - GetEntityForwardVector(ped) * moveSpeed
                end
                if IsControlPressed(0, 34) then -- A (strafe left)
                    local forward = GetEntityForwardVector(ped)
                    local right = vector3(forward.y, -forward.x, 0.0)
                    chinupPos = chinupPos - right * moveSpeed
                end
                if IsControlPressed(0, 35) then -- D (strafe right)
                    local forward = GetEntityForwardVector(ped)
                    local right = vector3(forward.y, -forward.x, 0.0)
                    chinupPos = chinupPos + right * moveSpeed
                end

                -- Height controls with finer adjustment
                if IsControlPressed(0, 10) then -- Page Up
                    chinupPos = vector3(chinupPos.x, chinupPos.y, chinupPos.z + moveSpeed)
                end
                if IsControlPressed(0, 11) then -- Page Down
                    chinupPos = vector3(chinupPos.x, chinupPos.y, chinupPos.z - moveSpeed)
                end

                -- Rotation controls
                if IsControlPressed(0, 44) then -- Q
                    SetEntityHeading(ped, heading - 1.0)
                end
                if IsControlPressed(0, 38) then -- E
                    SetEntityHeading(ped, heading + 1.0)
                end

                -- Copy to clipboard
                if IsControlJustPressed(0, 191) then -- Enter
                    local copyText = string.format(
                        "chinupCoords = vector3(%.2f, %.2f, %.2f), -- Where player grabs the bar\n" ..
                        "chinupHeading = %.1f, -- Direction to face the bar",
                        chinupPos.x, chinupPos.y, chinupPos.z, GetEntityHeading(ped)
                    )
                    lib.setClipboard(copyText)
                    lib.notify({ type = 'success', description = 'Chin-up coordinates copied to clipboard!' })
                end

                -- Apply position
                SetEntityCoords(ped, chinupPos.x, chinupPos.y, chinupPos.z, false, false, false, false)

                Wait(0)
            end
        end)
    else
        lib.hideTextUI()
        ClearPedTasks(PlayerPedId())
        lib.notify({ type = 'info', description = 'Chin-up positioning mode OFF' })
    end
end, false)

-- Test chin-up position from config
RegisterCommand('testchinupconfig', function(source, args)
    local chinupNum = tonumber(args[1]) or 1
    local chinup = Config.Chinups['chinup' .. chinupNum]

    if chinup and chinup.chinupCoords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, chinup.chinupCoords.x, chinup.chinupCoords.y, chinup.chinupCoords.z, false, false, false, false)
        SetEntityHeading(ped, chinup.chinupHeading or 0.0)
        lib.playAnim(ped, chinup.animDict, chinup.anim, 8.0, -8.0, -1, 1, 0.0, false, 0, false)
        lib.notify({ type = 'info', description = 'Testing chin-up ' .. chinupNum .. ' position' })
    else
        lib.notify({ type = 'error', description = 'Chin-up config not found' })
    end
end, false)