EMS = EMS or {}
EMS.PlayerData = nil
EMS.isDead = false
EMS.inLaststand = false
EMS.isInHospitalBed = false
EMS.deathTime = 0
EMS.laststandTime = 0
EMS.isBleeding = 0
EMS.injured = {}
EMS.canLeaveBed = true

local stationBlips = {}

local function createStationBlips()
    for _, b in pairs(stationBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    stationBlips = {}
    for _, st in ipairs(Config.Locations.stations or {}) do
        local blip = AddBlipForCoord(st.coords.x, st.coords.y, st.coords.z)
        SetBlipSprite(blip, st.sprite or 61)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, st.color or 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(st.label or 'Hospital')
        EndTextCommandSetBlipName(blip)
        stationBlips[#stationBlips + 1] = blip
    end
end

RegisterNetEvent('bsrp:client:onPlayerLoaded', function(data)
    EMS.PlayerData = data
    EMS.isDead = false
    EMS.inLaststand = false
    TriggerServerEvent('bsrp-ambulance:server:setDeathStatus', false)
    TriggerServerEvent('bsrp-ambulance:server:setLaststand', false)
end)

RegisterNetEvent('bsrp:client:onJobUpdate', function(job)
    EMS.PlayerData = FW.GetPlayerData()
    if EMS.PlayerData then
        EMS.PlayerData.job = job.name
        EMS.PlayerData.job_label = job.label
        EMS.PlayerData.job_grade = job.grade
        EMS.PlayerData.duty = job.duty
    end
end)

RegisterNetEvent('bsrp:client:playerData', function(data)
    EMS.PlayerData = data
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    createStationBlips()
    if FW.IsLoaded() then
        EMS.PlayerData = FW.GetPlayerData()
    end
end)

CreateThread(function()
    createStationBlips()
end)

function EMS.NotifyDeathUI(payload)
    SendNUIMessage({ action = 'death', data = payload })
end

function EMS.HideDeathUI()
    SendNUIMessage({ action = 'hideDeath' })
end

function EMS.RequestHelp()
    if Config.UsePsDispatch then
        if not FW.Dispatch('InjuriedPerson') then
            FW.DispatchCustom({
                message = 'Injured person',
                dispatchCode = 'civdown',
                code = '10-52',
                icon = 'fas fa-skull-crossbones',
                priority = 1,
                coords = GetEntityCoords(PlayerPedId()),
                jobs = { 'ems', 'leo' },
            })
        end
    end
    TriggerServerEvent('bsrp-ambulance:server:alert', 'Civilian needs medical assistance')
    FW.Notify('EMS has been notified', 'info')
end

exports('IsDead', function()
    return EMS.isDead
end)

exports('InLaststand', function()
    return EMS.inLaststand
end)

exports('IsEms', function()
    return FW.IsEms()
end)

-- EMS radial menu
local function openEmsMenu()
    if not FW.IsEmsOnDuty() then
        FW.Notify('On-duty EMS only', 'error')
        return
    end
    lib.registerContext({
        id = 'bsrp_ems_menu',
        title = 'EMS OPS',
        options = {
            { title = 'Revive Player', icon = 'heart-pulse', event = 'bsrp-ambulance:client:reviveTarget' },
            { title = 'Heal Player', icon = 'kit-medical', event = 'bsrp-ambulance:client:healTarget' },
            { title = 'Check Status', icon = 'stethoscope', event = 'bsrp-ambulance:client:checkStatus' },
            { title = 'Put in Vehicle', icon = 'truck-medical', event = 'bsrp-ambulance:client:putInVehicle' },
            { title = 'Panic / EMS Down', icon = 'bell', event = 'bsrp-ambulance:client:panic' },
            { title = 'Open MDT', icon = 'tablet', event = 'bsrp-ambulance:client:mdt' },
        }
    })
    lib.showContext('bsrp_ems_menu')
end

RegisterCommand('emsmenu', openEmsMenu, false)
RegisterKeyMapping('emsmenu', 'EMS Job Menu', 'keyboard', 'F6')

RegisterNetEvent('bsrp-ambulance:client:mdt', function()
    if Config.UsePsMdt then FW.OpenMDT() end
end)

RegisterNetEvent('bsrp-ambulance:client:panic', function()
    if not FW.IsEmsOnDuty() then return end
    if Config.UsePsDispatch then
        FW.Dispatch('EmsDown')
    end
    FW.Notify('EMS distress sent', 'error')
end)
