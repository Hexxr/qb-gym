CreateThread(function()
    while not QBCore or not QBCore.Functions do
    Wait(50)
end

    QBCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, controlDisables, animation, prop, onFinish, onCancel)
        lib.progressBar({
            duration = duration or 5000,
            label = label or 'Progress...',
            useWhileDead = useWhileDead or false,
            canCancel = canCancel or true,
            disable = controlDisables or {},
            anim = animation or {},
            onFinish = onFinish,
            onCancel = onCancel
        })
    end
end)
