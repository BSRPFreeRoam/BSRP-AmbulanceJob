local death = {}     -- [src] = true
local laststand = {} -- [src] = true
local bedTaken = {}  -- [index] = src

local function getPlayer(src)
    if GetResourceState('bsrp') ~= 'started' then return nil end
    return exports.bsrp:GetPlayer(src)
end

local function isEmsOnDuty(player)
    if not player or not player.duty then return false end
    if Config.EmsJobs and Config.EmsJobs[player.job] then return true end
    return exports.bsrp:GetJobType(player.job) == 'ems'
end

local function notify(src, msg, nType)
    TriggerClientEvent('bsrp:client:notify', src, msg, nType or 'info')
end

local function countEmsOnDuty()
    local n = 0
    if GetResourceState('bsrp') ~= 'started' then return 0 end
    for _, player in pairs(exports.bsrp:GetPlayers() or {}) do
        if isEmsOnDuty(player) then n = n + 1 end
    end
    return n
end

CreateThread(function()
    Wait(1000)
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:RegisterStash('ems_shared', 'EMS Supplies', 80, 400000, false)
        end)
    end
end)

RegisterNetEvent('bsrp-ambulance:server:setDeathStatus', function(state)
    death[source] = state and true or false
    if GetResourceState('bsrp') == 'started' then
        exports.bsrp:SetMetadata(source, 'isdead', state and true or false)
    end
end)

RegisterNetEvent('bsrp-ambulance:server:setLaststand', function(state)
    laststand[source] = state and true or false
    if GetResourceState('bsrp') == 'started' then
        exports.bsrp:SetMetadata(source, 'inlaststand', state and true or false)
    end
end)

RegisterNetEvent('bsrp-ambulance:server:alert', function(text)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = ped and ped ~= 0 and GetEntityCoords(ped) or vector3(0, 0, 0)
    if GetResourceState('bsrp') ~= 'started' then return end
    for tSrc, player in pairs(exports.bsrp:GetPlayers() or {}) do
        if isEmsOnDuty(player) then
            TriggerClientEvent('bsrp:client:notify', tSrc, ('EMS: %s'):format(text or 'Alert'), 'error')
            TriggerClientEvent('bsrp-ambulance:client:alertBlip', tSrc, { x = coords.x, y = coords.y, z = coords.z }, text)
        end
    end
end)

RegisterNetEvent('bsrp-ambulance:server:revive', function(target)
    local src = source
    local player = getPlayer(src)
    if not isEmsOnDuty(player) then
        notify(src, 'On-duty EMS only', 'error')
        return
    end
    target = tonumber(target)
    if not getPlayer(target) then return end

    if GetResourceState('ox_inventory') == 'started' then
        local item = Config.Items.firstaid or 'firstaid'
        local count = exports.ox_inventory:GetItemCount(src, item)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(src, item, 1)
        end
    end

    death[target] = nil
    laststand[target] = nil
    TriggerClientEvent('bsrp-ambulance:client:Revive', target)
    notify(src, 'Patient revived', 'success')
end)

RegisterNetEvent('bsrp-ambulance:server:heal', function(target)
    local src = source
    if not isEmsOnDuty(getPlayer(src)) then return end
    target = tonumber(target)
    if not getPlayer(target) then return end
    if GetResourceState('ox_inventory') == 'started' then
        local item = Config.Items.bandage or 'bandage'
        local count = exports.ox_inventory:GetItemCount(src, item)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(src, item, 1)
        end
    end
    TriggerClientEvent('bsrp-ambulance:client:Heal', target)
    notify(src, 'Patient treated', 'success')
end)

RegisterNetEvent('bsrp-ambulance:server:status', function(target)
    local src = source
    if not isEmsOnDuty(getPlayer(src)) then return end
    target = tonumber(target)
    local other = getPlayer(target)
    if not other then return end
    TriggerClientEvent('bsrp-ambulance:client:statusResult', src, {
        name = other.name,
        id = target,
        dead = death[target] == true,
        laststand = laststand[target] == true,
        bleeding = 0,
    })
end)

RegisterNetEvent('bsrp-ambulance:server:putInVehicle', function(target)
    local src = source
    if not isEmsOnDuty(getPlayer(src)) then return end
    target = tonumber(target)
    if not getPlayer(target) then return end
    TriggerClientEvent('bsrp-ambulance:client:putInVehicleClient', target)
end)

RegisterNetEvent('bsrp-ambulance:server:openStash', function()
    local src = source
    local player = getPlayer(src)
    if not isEmsOnDuty(player) then return end
    local id = 'ems_locker_' .. tostring(player.identifier or src):gsub('[^%w_]', '_')
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:RegisterStash(id, 'EMS Locker', 50, 100000, true)
        end)
    end
    TriggerClientEvent('bsrp-ambulance:client:openStash', src, id)
end)

RegisterNetEvent('bsrp-ambulance:server:checkin', function(hospitalIndex)
    local src = source
    local player = getPlayer(src)
    if not player then return end

    local docs = countEmsOnDuty()
    if docs >= (Config.MinimalDoctors or 2) then
        notify(src, 'EMS is available — wait for a medic', 'error')
        return
    end

    if not exports.bsrp:RemoveMoney(src, 'bank', Config.BillCost, 'hospital-checkin') then
        if not exports.bsrp:RemoveMoney(src, 'cash', Config.BillCost, 'hospital-checkin') then
            notify(src, 'Not enough money for treatment', 'error')
            return
        end
    end

    -- pick free bed
    local bed
    for i, b in ipairs(Config.Locations.beds or {}) do
        if not bedTaken[i] then
            bedTaken[i] = src
            bed = b
            break
        end
    end
    if not bed then
        bed = Config.Locations.beds and Config.Locations.beds[1]
    end

    death[src] = nil
    laststand[src] = nil
    TriggerClientEvent('bsrp-ambulance:client:sendToBed', src, bed)
    notify(src, ('Hospital bill: $%s'):format(Config.BillCost), 'info')
end)

RegisterNetEvent('bsrp-ambulance:server:respawn', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end

    if Config.WipeInventoryOnRespawn and GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:ClearInventory(src)
        end)
        notify(src, 'Your possessions were taken', 'error')
    end

    if not exports.bsrp:RemoveMoney(src, 'bank', Config.BillCost, 'hospital-respawn') then
        exports.bsrp:RemoveMoney(src, 'cash', Config.BillCost, 'hospital-respawn')
    end

    local bed = Config.Locations.beds and Config.Locations.beds[1]
    death[src] = nil
    laststand[src] = nil
    TriggerClientEvent('bsrp-ambulance:client:sendToBed', src, bed)
end)

RegisterCommand('revive', function(src, args)
    if src == 0 then
        local target = tonumber(args[1])
        if target then TriggerClientEvent('bsrp-ambulance:client:Revive', target) end
        return
    end
    local player = getPlayer(src)
    if not player then return end
    local isAdmin = (player.admin_level or 0) >= 1
    local target = tonumber(args[1]) or src
    if isAdmin then
        TriggerClientEvent('bsrp-ambulance:client:Revive', target)
        notify(src, 'Revived', 'success')
    elseif isEmsOnDuty(player) then
        TriggerClientEvent('bsrp-ambulance:client:reviveTarget', src)
    else
        notify(src, 'Not allowed', 'error')
    end
end, false)

RegisterCommand('kill', function(src, args)
    if src == 0 then return end
    local player = getPlayer(src)
    if not player or (player.admin_level or 0) < 1 then return end
    local target = tonumber(args[1]) or src
    TriggerClientEvent('bsrp-ambulance:client:adminKill', target)
end, false)

AddEventHandler('playerDropped', function()
    local src = source
    death[src] = nil
    laststand[src] = nil
    for i, taker in pairs(bedTaken) do
        if taker == src then bedTaken[i] = nil end
    end
end)

exports('IsDead', function(src)
    return death[src] == true
end)

exports('InLaststand', function(src)
    return laststand[src] == true
end)
