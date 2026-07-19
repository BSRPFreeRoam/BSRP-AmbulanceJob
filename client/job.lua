local function spawnJobVehicle(model, coords)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then
        FW.Notify('Invalid vehicle', 'error')
        return
    end
    lib.requestModel(hash, 5000)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, 'AMBU' .. tostring(math.random(1000, 9999)))
    SetVehicleEngineOn(veh, true, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)
    FW.Notify('Ambulance deployed', 'success')
end

local function openGarage(spawnCoords)
    if not FW.IsEmsOnDuty() then
        FW.Notify('On-duty EMS only', 'error')
        return
    end
    local grade = FW.Grade()
    local options = {}
    for g, list in pairs(Config.AuthorizedVehicles) do
        if grade >= g then
            for _, v in ipairs(list) do
                options[#options + 1] = {
                    title = v.label,
                    icon = 'truck-medical',
                    onSelect = function()
                        spawnJobVehicle(v.model, spawnCoords)
                    end,
                }
            end
        end
    end
    lib.registerContext({ id = 'bsrp_ems_garage', title = 'EMS FLEET', options = options })
    lib.showContext('bsrp_ems_garage')
end

RegisterNetEvent('bsrp-ambulance:client:reviveTarget', function()
    if not FW.IsEmsOnDuty() then return end
    local _, _, sid = FW.ClosestPlayer(2.5)
    if not sid then
        FW.Notify('No one nearby', 'error')
        return
    end
    if not FW.HasItem(Config.Items.firstaid, 1) and not FW.HasItem('bandage', 1) then
        -- still allow revive without item if configured; prefer firstaid
    end
    if lib.progressCircle({
        duration = (Config.ReviveInterval or 15) * 1000,
        label = 'Reviving...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' },
    }) then
        TriggerServerEvent('bsrp-ambulance:server:revive', sid)
    end
end)

RegisterNetEvent('bsrp-ambulance:client:healTarget', function()
    if not FW.IsEmsOnDuty() then return end
    local _, _, sid = FW.ClosestPlayer(2.5)
    if not sid then
        FW.Notify('No one nearby', 'error')
        return
    end
    if lib.progressCircle({
        duration = (Config.HealInterval or 8) * 1000,
        label = 'Treating wounds...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }) then
        TriggerServerEvent('bsrp-ambulance:server:heal', sid)
    end
end)

RegisterNetEvent('bsrp-ambulance:client:checkStatus', function()
    if not FW.IsEmsOnDuty() then return end
    local _, _, sid = FW.ClosestPlayer(2.5)
    if not sid then
        FW.Notify('No one nearby', 'error')
        return
    end
    TriggerServerEvent('bsrp-ambulance:server:status', sid)
end)

RegisterNetEvent('bsrp-ambulance:client:statusResult', function(data)
    lib.registerContext({
        id = 'bsrp_ems_status',
        title = 'PATIENT STATUS',
        options = {
            { title = data.name or 'Patient', description = ('ID %s'):format(data.id or '?'), icon = 'user' },
            { title = data.dead and 'DECEASED' or (data.laststand and 'CRITICAL' or 'STABLE'), icon = 'heart-pulse' },
            { title = ('Bleeding: %s'):format(data.bleeding or 0), icon = 'droplet' },
        }
    })
    lib.showContext('bsrp_ems_status')
end)

RegisterNetEvent('bsrp-ambulance:client:putInVehicle', function()
    if not FW.IsEmsOnDuty() then return end
    local _, _, sid = FW.ClosestPlayer(3.0)
    if not sid then
        FW.Notify('No one nearby', 'error')
        return
    end
    TriggerServerEvent('bsrp-ambulance:server:putInVehicle', sid)
end)

RegisterNetEvent('bsrp-ambulance:client:putInVehicleClient', function()
    local ped = PlayerPedId()
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), 6.0, false)
    if not vehicle then return end
    for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if IsVehicleSeatFree(vehicle, i) then
            TaskWarpPedIntoVehicle(ped, vehicle, i)
            return
        end
    end
end)

local function registerTargets()
    if GetResourceState('ox_target') ~= 'started' then return end

    for i, coords in ipairs(Config.Locations.duty or {}) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.2,
            options = {
                {
                    name = 'bsrp_ems_duty_' .. i,
                    icon = 'fa-solid fa-clipboard-user',
                    label = 'Toggle EMS Duty',
                    canInteract = function() return FW.IsEms() end,
                    onSelect = function()
                        TriggerServerEvent('bsrp:server:toggleDuty')
                    end,
                },
            },
        })
    end

    for i, coords in ipairs(Config.Locations.stash or {}) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.2,
            options = {
                {
                    name = 'bsrp_ems_stash_' .. i,
                    icon = 'fa-solid fa-box',
                    label = 'EMS Locker',
                    canInteract = function() return FW.IsEmsOnDuty() end,
                    onSelect = function()
                        TriggerServerEvent('bsrp-ambulance:server:openStash')
                    end,
                },
            },
        })
    end

    for i, coords in ipairs(Config.Locations.checking or {}) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.4,
            options = {
                {
                    name = 'bsrp_ems_checkin_' .. i,
                    icon = 'fa-solid fa-bed-pulse',
                    label = 'Hospital Check-In ($' .. tostring(Config.BillCost) .. ')',
                    onSelect = function()
                        TriggerServerEvent('bsrp-ambulance:server:checkin', i)
                    end,
                },
            },
        })
    end

    for i, coords in ipairs(Config.Locations.vehicle or {}) do
        exports.ox_target:addSphereZone({
            coords = vec3(coords.x, coords.y, coords.z),
            radius = 2.0,
            options = {
                {
                    name = 'bsrp_ems_garage_' .. i,
                    icon = 'fa-solid fa-truck-medical',
                    label = 'EMS Garage',
                    canInteract = function() return FW.IsEmsOnDuty() end,
                    onSelect = function() openGarage(coords) end,
                },
                {
                    name = 'bsrp_ems_store_' .. i,
                    icon = 'fa-solid fa-square-parking',
                    label = 'Store Vehicle',
                    canInteract = function()
                        return FW.IsEmsOnDuty() and IsPedInAnyVehicle(PlayerPedId(), false)
                    end,
                    onSelect = function()
                        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                        if veh ~= 0 then DeleteEntity(veh) end
                    end,
                },
            },
        })
    end

    for i, coords in ipairs(Config.Locations.helicopter or {}) do
        exports.ox_target:addSphereZone({
            coords = vec3(coords.x, coords.y, coords.z),
            radius = 2.5,
            options = {
                {
                    name = 'bsrp_ems_heli_' .. i,
                    icon = 'fa-solid fa-helicopter',
                    label = 'EMS Helicopter',
                    canInteract = function() return FW.IsEmsOnDuty() and FW.Grade() >= 2 end,
                    onSelect = function()
                        spawnJobVehicle(Config.Helicopter, coords)
                    end,
                },
            },
        })
    end

    exports.ox_target:addGlobalPlayer({
        {
            name = 'bsrp_ems_revive',
            icon = 'fa-solid fa-heart-pulse',
            label = 'Revive',
            distance = 2.0,
            canInteract = function() return FW.IsEmsOnDuty() end,
            onSelect = function(data)
                local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                if lib.progressCircle({
                    duration = (Config.ReviveInterval or 15) * 1000,
                    label = 'Reviving...',
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, combat = true },
                    anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' },
                }) then
                    TriggerServerEvent('bsrp-ambulance:server:revive', sid)
                end
            end,
        },
        {
            name = 'bsrp_ems_heal',
            icon = 'fa-solid fa-kit-medical',
            label = 'Heal',
            distance = 2.0,
            canInteract = function() return FW.IsEmsOnDuty() end,
            onSelect = function(data)
                local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerServerEvent('bsrp-ambulance:server:heal', sid)
            end,
        },
    })
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do Wait(200) end
    Wait(500)
    registerTargets()
end)

RegisterNetEvent('bsrp-ambulance:client:openStash', function(id)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    exports.ox_inventory:openInventory('stash', id)
end)
