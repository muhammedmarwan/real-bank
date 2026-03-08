local function BuildQboxFallbackObject()
    local object = {
        Functions = {}
    }

    if IsDuplicityVersion() then
        object.Functions.GetPlayer = function(source)
            return exports.qbx_core:GetPlayer(source)
        end

        object.Functions.GetSource = function(citizenid)
            local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
            return target and target.PlayerData and target.PlayerData.source or 0
        end

        object.Functions.CreateCallback = function(name, cb)
            lib.callback.register(name, function(source, ...)
                local returnData = nil
                cb(source, function(data)
                    returnData = data
                end, ...)
                return returnData
            end)
        end
    else
        object.Functions.GetPlayerData = function()
            return exports.qbx_core:GetPlayerData()
        end

        object.Functions.TriggerCallback = function(name, cb, payload)
            local result = lib.callback.await(name, false, payload)
            cb(result)
        end
    end

    return object
end

function GetCore()
    local object = nil
    local attempts = 0

    while not object and attempts < 10 do
        local status = pcall(function()
            object = exports['qb-core']:GetCoreObject()
        end)

        if status and object then
            break
        end

        attempts = attempts + 1
        Citizen.Wait(250)
    end

    if not object then
        local qboxState = GetResourceState('qbx_core')
        if qboxState == 'started' then
            object = BuildQboxFallbackObject()
            print('[real-bank] qb-core bridge not found, using qbx_core fallback adapter.')
        else
            print('[real-bank] Failed to fetch framework object. Ensure qbx_core is started.')
        end
    end

    return object, 'qbox'
end
