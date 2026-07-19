function EMS.KillPlayer()
    if EMS.isDead then return end
    EMS.inLaststand = false
    EMS.isDead = true
    EMS.deathTime = Config.DeathTime

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerServerEvent('bsrp-ambulance:server:setDeathStatus', true)
    TriggerServerEvent('bsrp-ambulance:server:setLaststand', false)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    SetEntityInvincible(ped, true)

    if Config.UsePsDispatch then
        FW.Dispatch('DeceasedPerson')
    end
    TriggerServerEvent('bsrp-ambulance:server:alert', 'Civilian deceased')

    CreateThread(function()
        local hold = 0
        while EMS.isDead do
            Wait(0)
            local p = PlayerPedId()
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 38, true)
            EnableControlAction(0, 47, true)

            if IsPedDeadOrDying(p, true) then
                local c = GetEntityCoords(p)
                NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(p), true, false)
                p = PlayerPedId()
                SetEntityHealth(p, 0)
                SetEntityInvincible(p, true)
            end

            EMS.NotifyDeathUI({
                mode = 'dead',
                time = EMS.deathTime,
                title = 'VITALS OFFLINE',
                line1 = ('RESPAWN AVAILABLE IN %ss'):format(math.max(0, EMS.deathTime)),
                line2 = EMS.deathTime > 0 and 'PRESS G TO REQUEST EMS' or 'HOLD E TO RESPAWN AT HOSPITAL',
            })

            if IsControlJustPressed(0, 47) then
                EMS.RequestHelp()
            end

            if EMS.deathTime <= 0 and IsControlPressed(0, 38) then
                hold = hold + 1
                if hold >= 120 then
                    hold = 0
                    TriggerEvent('bsrp-ambulance:client:respawn')
                    break
                end
            else
                hold = math.max(0, hold - 2)
            end
        end
    end)

    CreateThread(function()
        while EMS.isDead do
            Wait(1000)
            EMS.deathTime = EMS.deathTime - 1
            if EMS.deathTime < 0 then EMS.deathTime = 0 end
        end
    end)
end

function EMS.RevivePlayer(full)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    EMS.isDead = false
    EMS.inLaststand = false
    EMS.isBleeding = 0
    EMS.injured = {}
    EMS.HideDeathUI()

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, full and GetEntityMaxHealth(ped) or 160)
    if full then
        SetPedArmour(ped, 0)
        ClearPedTasks(ped)
    end

    TriggerServerEvent('bsrp-ambulance:server:setDeathStatus', false)
    TriggerServerEvent('bsrp-ambulance:server:setLaststand', false)
    TriggerEvent('bsrp-ambulance:client:onRevive')
    FW.Notify('You have been revived', 'success')
end

RegisterNetEvent('bsrp-ambulance:client:Revive', function()
    EMS.RevivePlayer(true)
end)

RegisterNetEvent('bsrp-ambulance:client:Heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    EMS.isBleeding = 0
    EMS.injured = {}
    ClearPedBloodDamage(ped)
    FW.Notify('You have been healed', 'success')
end)

RegisterNetEvent('bsrp-ambulance:client:respawn', function()
    if not EMS.isDead then return end
    TriggerServerEvent('bsrp-ambulance:server:respawn')
end)

RegisterNetEvent('bsrp-ambulance:client:sendToBed', function(bed)
    if type(bed) ~= 'table' or not bed.coords then return end
    EMS.isInHospitalBed = true
    EMS.canLeaveBed = false
    local ped = PlayerPedId()
    local c = bed.coords
    DoScreenFadeOut(500)
    Wait(550)
    SetEntityCoords(ped, c.x, c.y, c.z + 0.3, false, false, false, false)
    SetEntityHeading(ped, c.w or 0.0)
    EMS.RevivePlayer(true)
    FreezeEntityPosition(ped, true)
    FW.LoadAnim('anim@gangops@morgue@table@')
    TaskPlayAnim(ped, 'anim@gangops@morgue@table@', 'body_search', 8.0, 1.0, -1, 1, 0, false, false, false)
    Wait(300)
    DoScreenFadeIn(500)

    CreateThread(function()
        Wait((Config.CheckInTime or 20) * 1000)
        EMS.canLeaveBed = true
        FW.Notify('Press E to leave the bed', 'info')
        while EMS.isInHospitalBed do
            Wait(0)
            if EMS.canLeaveBed and IsControlJustPressed(0, 38) then
                EMS.isInHospitalBed = false
                FreezeEntityPosition(PlayerPedId(), false)
                ClearPedTasks(PlayerPedId())
                EMS.HideDeathUI()
                break
            end
        end
    end)
end)

-- Admin / external revive hooks
RegisterNetEvent('bsrp:client:admin:revive', function()
    EMS.RevivePlayer(true)
end)

RegisterNetEvent('bsrp-ambulance:client:adminKill', function()
    EMS.KillPlayer()
end)

RegisterNetEvent('bsrp-ambulance:client:alertBlip', function(coords, text)
    if not coords then return end
    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, 153)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(text or 'EMS Alert')
    EndTextCommandSetBlipName(blip)
    SetTimeout(60000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)
