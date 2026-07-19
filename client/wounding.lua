-- Lightweight bleeding / injury simulation (no qb-core)

CreateThread(function()
    while true do
        Wait((Config.BleedTickRate or 30) * 1000)
        if not FW.IsLoaded() or EMS.isDead or EMS.inLaststand or EMS.isInHospitalBed then
            goto continue
        end
        if EMS.isBleeding and EMS.isBleeding > 0 then
            local ped = PlayerPedId()
            local dmg = (Config.BleedTickDamage or 6) * EMS.isBleeding
            local hp = GetEntityHealth(ped)
            SetEntityHealth(ped, math.max(100, hp - dmg))
            if EMS.isBleeding >= 2 then
                FW.Notify('You are bleeding...', 'error')
            end
            if GetEntityHealth(ped) <= 105 and not EMS.inLaststand then
                EMS.EnterLaststand()
            end
        end
        ::continue::
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    if victim ~= PlayerPedId() then return end
    if EMS.isDead or EMS.inLaststand then return end

    local ped = PlayerPedId()
    if HasEntityBeenDamagedByWeapon(ped, 0, 2) then
        -- any weapon damage chance to start bleeding
        if math.random(100) <= 35 then
            EMS.isBleeding = math.min(4, (EMS.isBleeding or 0) + 1)
        end
    end
    ClearEntityLastDamageEntity(ped)
end)

RegisterNetEvent('bsrp-ambulance:client:useBandage', function()
    if EMS.isDead then return end
    if lib.progressCircle({
        duration = 4000,
        label = 'Applying bandage...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }) then
        EMS.isBleeding = math.max(0, (EMS.isBleeding or 0) - 1)
        local ped = PlayerPedId()
        local hp = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), hp + 15))
        FW.Notify('Bandage applied', 'success')
    end
end)

RegisterNetEvent('bsrp-ambulance:client:useFirstAid', function()
    if EMS.isDead then return end
    if lib.progressCircle({
        duration = 6000,
        label = 'Using first aid...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }) then
        EMS.isBleeding = 0
        local ped = PlayerPedId()
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + 40))
        FW.Notify('First aid applied', 'success')
    end
end)
