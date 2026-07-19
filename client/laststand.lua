local laststandDict = 'combat@damage@writhe'
local laststandAnim = 'writhe_loop'

function EMS.EnterLaststand(attacker)
    if EMS.isDead or EMS.inLaststand then return end
    EMS.inLaststand = true
    EMS.laststandTime = Config.LaststandTime
    local ped = PlayerPedId()

    TriggerServerEvent('bsrp-ambulance:server:setLaststand', true)

    FW.LoadAnim(laststandDict)
    SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
    Wait(500)
    ClearPedTasksImmediately(ped)
    TaskPlayAnim(ped, laststandDict, laststandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)

    if Config.UsePsDispatch then
        FW.Dispatch('InjuriedPerson')
    end
    TriggerServerEvent('bsrp-ambulance:server:alert', 'Civilian down (critical)')

    CreateThread(function()
        local hold = 0
        while EMS.inLaststand and not EMS.isDead do
            Wait(0)
            local ped2 = PlayerPedId()
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true) -- chat
            EnableControlAction(0, 38, true)  -- E
            EnableControlAction(0, 47, true)  -- G

            if not IsEntityPlayingAnim(ped2, laststandDict, laststandAnim, 3) then
                TaskPlayAnim(ped2, laststandDict, laststandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
            end

            EMS.NotifyDeathUI({
                mode = 'laststand',
                time = EMS.laststandTime,
                title = 'CRITICAL CONDITION',
                line1 = ('BLEED OUT IN %ss'):format(math.max(0, EMS.laststandTime)),
                line2 = 'PRESS G TO REQUEST EMS  ·  HOLD E TO GIVE UP',
            })

            if IsControlPressed(0, 38) then
                hold = hold + 1
                if hold >= 150 then -- ~3s at 0 wait frame-ish
                    hold = 0
                    EMS.KillPlayer()
                    break
                end
            else
                hold = 0
            end

            if IsControlJustPressed(0, 47) then
                EMS.RequestHelp()
            end
        end
    end)

    CreateThread(function()
        while EMS.inLaststand and not EMS.isDead do
            Wait(1000)
            EMS.laststandTime = EMS.laststandTime - 1
            if EMS.laststandTime <= 0 then
                EMS.KillPlayer()
                break
            end
        end
    end)
end

function EMS.ExitLaststand()
    if not EMS.inLaststand then return end
    EMS.inLaststand = false
    TriggerServerEvent('bsrp-ambulance:server:setLaststand', false)
    ClearPedTasks(PlayerPedId())
    EMS.HideDeathUI()
end

-- Damage → laststand threshold
CreateThread(function()
    local lastHealth = 200
    while true do
        Wait(200)
        if not FW.IsLoaded() or EMS.isDead or EMS.isInHospitalBed then
            goto continue
        end
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        if health < lastHealth and health <= 140 and health > 100 and not EMS.inLaststand then
            -- heavy hit → laststand instead of instant death if still "alive"
            if health <= 115 then
                SetEntityHealth(ped, 150)
                EMS.EnterLaststand()
            end
        end
        -- game death
        if IsEntityDead(ped) or health <= 100 then
            if not EMS.isDead then
                if EMS.inLaststand then
                    EMS.KillPlayer()
                else
                    EMS.EnterLaststand()
                    Wait(100)
                    if IsEntityDead(PlayerPedId()) then
                        EMS.KillPlayer()
                    end
                end
            end
        end
        lastHealth = GetEntityHealth(PlayerPedId())
        ::continue::
    end
end)
