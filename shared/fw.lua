--[[
    BSRP framework helpers for ambulance / EMS job.
    Soft-optional: ps-dispatch, ps-mdt (never hard dependencies).
]]

FW = FW or {}

function FW.Started(name)
    return GetResourceState(name) == 'started'
end

function FW.Notify(msg, nType, duration)
    nType = nType or 'info'
    if FW.Started('bsrp') then
        local ok = pcall(function()
            exports.bsrp:Notify(msg, nType)
        end)
        if ok then return end
    end
    if lib and lib.notify then
        lib.notify({ description = msg, type = nType == 'error' and 'error' or (nType == 'success' and 'success' or 'inform'), duration = duration or 4000 })
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

function FW.GetPlayerData()
    if not FW.Started('bsrp') then return nil end
    local ok, data = pcall(function()
        return exports.bsrp:GetPlayerData()
    end)
    if ok then return data end
    return nil
end

function FW.IsLoaded()
    if not FW.Started('bsrp') then return false end
    local ok, v = pcall(function()
        return exports.bsrp:IsPlayerLoaded()
    end)
    return ok and v == true
end

function FW.GetJobType(jobName)
    if not FW.Started('bsrp') then return 'civ' end
    local ok, t = pcall(function()
        return exports.bsrp:GetJobType(jobName)
    end)
    if ok and t then return t end
    return 'civ'
end

function FW.IsEms(data)
    data = data or FW.GetPlayerData()
    if not data or not data.job then return false end
    if Config.EmsJobs and Config.EmsJobs[data.job] then return true end
    return FW.GetJobType(data.job) == 'ems'
end

function FW.OnDuty(data)
    data = data or FW.GetPlayerData()
    return data and data.duty == true
end

function FW.IsEmsOnDuty(data)
    data = data or FW.GetPlayerData()
    return FW.IsEms(data) and FW.OnDuty(data)
end

function FW.Grade(data)
    data = data or FW.GetPlayerData()
    return (data and tonumber(data.job_grade)) or 0
end

function FW.Dispatch(exportName, ...)
    if not FW.Started('ps-dispatch') then return false end
    local args = { ... }
    local ok = pcall(function()
        exports['ps-dispatch'][exportName](table.unpack(args))
    end)
    return ok
end

function FW.DispatchCustom(data)
    if not FW.Started('ps-dispatch') then return false end
    local ok = pcall(function()
        exports['ps-dispatch']:CustomAlert(data)
    end)
    return ok
end

function FW.OpenMDT()
    if not FW.Started('ps-mdt') then
        FW.Notify('MDT is not available.', 'error')
        return false
    end
    local ok = pcall(function()
        if exports['ps-mdt'] and exports['ps-mdt'].OpenMDT then
            exports['ps-mdt']:OpenMDT()
        else
            ExecuteCommand('mdt')
        end
    end)
    if not ok then
        ExecuteCommand('mdt')
    end
    return true
end

function FW.ClosestPlayer(maxDist)
    maxDist = maxDist or 2.5
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closest, closestDist = nil, maxDist + 0.01
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local d = #(GetEntityCoords(ped) - myCoords)
                if d < closestDist then
                    closestDist = d
                    closest = player
                end
            end
        end
    end
    if closest then
        return closest, closestDist, GetPlayerServerId(closest)
    end
    return nil, nil, nil
end

function FW.LoadAnim(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 100 do
        Wait(10)
        t = t + 1
    end
end

function FW.HasItem(item, count)
    if not FW.Started('ox_inventory') then return false end
    count = count or 1
    local ok, n = pcall(function()
        return exports.ox_inventory:Search('count', item)
    end)
    return ok and (n or 0) >= count
end

function FW.OpenStash(id)
    if not FW.Started('ox_inventory') then return end
    exports.ox_inventory:openInventory('stash', id)
end
