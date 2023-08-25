local CurrentProp = nil
local CurrentParticleFX = nil
local CurrentAnim = nil

local function FormatAnim(anim)
    if not anim then return {} end
    return {
        dict = anim.dict,
        name = anim.name,
        flags = anim.flags,
        task = anim.task,
    }
end

local function FormatPropData(prop)
    if not prop then return {} end
    local coords = GetPedBoneCoords(PlayerPedId(), prop.bone) + prop.offset
    return {
        name = prop.name,
        bone = prop.bone,
        coords = coords,
        rotation = prop.rotation,
    }
end

local function SpawnParticles(particleDict, particleName, offsetPos, offsetRot, duration)
    if CurrentParticleFX then
        StopParticleFxLooped(CurrentParticleFX, 0)
        CurrentParticleFX = nil
    end
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    RequestNamedPtfxAsset(particleDict)
    local timeout = 500
    while not HasNamedPtfxAssetLoaded(particleDict) and timeout > 0 do
        Citizen.Wait(0)
        timeout = timeout - 1
    end
    if timeout <= 0 then return end
    UseParticleFxAssetNextCall(particleDict)
    local particle = StartParticleFxLoopedOnEntity(particleName, playerPed, offsetPos.x, offsetPos.y, offsetPos.z, offsetRot.x, offsetRot.y, playerHeading + offsetRot.z, 1.0, false, false, false)
    CurrentParticleFX = particle
    if not duration then return end
    SetTimeout(duration, function()
        StopParticleFxLooped(particle, 0)
        CurrentParticleFX = nil
    end)
end

RegisterNetEvent('pandadrugs:client:UseDrug', function(drugName, method, itemName, effects, info)
    -- local data = method ~= 'Eat' and Config.Methods[method] and Config.Methods[method][itemName] or Config.Methods[method]
    -- assert(data, 'Method does not exist ')

    -- local prop = data.prop
    -- local propData = FormatPropData(prop)
    -- local anim = data.anim
    -- local animData = FormatAnim(anim)

    -- local particle = data.particle
    -- if particle then
    --     SpawnParticles(particle.dict, particle.name, particle.offsetPos, particle.offsetRot, particle.duration)
    -- end
    QBCore.Functions.Progressbar('useDrug', 'Consuming Drug', effects["Consumption Time"] or 1500, false, true, {
            disableMovement = false,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        },
        effects.Animation or {},
        effects.PropData or {},
        {}, function()
            ClearPedTasks(PlayerPedId())
            StartEffect(itemName, effects, info)
        end, function()
            QBCore.Functions.Notify('Cancelled', 'error')
        end
    )

end)