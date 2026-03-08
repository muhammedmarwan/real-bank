Config.DrawText3D = function(msg, coords)
    AddTextEntry('esxFloatingHelpNotification', msg)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

local oxTargetsCreated = false
local fallbackThreadStarted = false

local function CreateOxTargetInteractions()
    if oxTargetsCreated then
        return
    end

    oxTargetsCreated = true

    local ok = pcall(function()
        for i, v in pairs(Config.BankLocations) do
            exports.ox_target:addBoxZone({
                coords = vector3(v.Coords.x, v.Coords.y, v.Coords.z),
                size = vec3(1.6, 1.6, 2.6),
                rotation = 0.0,
                debug = false,
                options = {
                    {
                        name = ('real-bank:open-bank:%s'):format(i),
                        icon = 'fas fa-building-columns',
                        label = 'Open Bank',
                        distance = 2.0,
                        onSelect = function()
                            TriggerEvent('real-bank:OpenNormalBank')
                        end,
                    },
                    {
                        name = ('real-bank:open-society-bank:%s'):format(i),
                        icon = 'fas fa-briefcase',
                        label = 'Open Society Bank',
                        distance = 2.0,
                        onSelect = function()
                            TriggerEvent('real-bank:OpenSocietyBank')
                        end,
                    }
                }
            })
        end

        exports.ox_target:addModel(Config.ATMs, {
            {
                name = 'real-bank:open-atm',
                icon = 'fas fa-credit-card',
                label = 'Open ATM',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('real-bank:OpenATMFunction')
                end,
            }
        })

        exports.ox_target:addSphereZone({
            coords = vector3(Config.GetCreditCard.x, Config.GetCreditCard.y, Config.GetCreditCard.z),
            radius = 1.2,
            debug = false,
            options = {
                {
                    name = 'real-bank:get-credit-card',
                    icon = 'fas fa-credit-card',
                    label = 'Get Credit Card',
                    distance = 2.0,
                    onSelect = function()
                        TriggerEvent('real-bank:BankSettings', 'Get')
                    end,
                },
                {
                    name = 'real-bank:change-password',
                    icon = 'fas fa-key',
                    label = 'Change Password',
                    distance = 2.0,
                    onSelect = function()
                        TriggerEvent('real-bank:BankSettings', 'Change')
                    end,
                }
            }
        })
    end)

    if not ok then
        oxTargetsCreated = false
    end
end

local function OpenSettingsMenu()
    lib.registerContext({
        id = 'real-bank:settings-menu',
        title = 'Bank Settings',
        options = {
            {
                title = 'Get Credit Card',
                icon = 'credit-card',
                onSelect = function()
                    TriggerEvent('real-bank:BankSettings', 'Get')
                end
            },
            {
                title = 'Change Password',
                icon = 'key',
                onSelect = function()
                    TriggerEvent('real-bank:BankSettings', 'Change')
                end
            }
        }
    })

    lib.showContext('real-bank:settings-menu')
end

local function StartFallbackInteractionThread()
    if fallbackThreadStarted then
        return
    end

    fallbackThreadStarted = true

    Citizen.CreateThread(function()
        while true do
            local sleep = 1500
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)

            local settingsDist = #(playerCoords - Config.GetCreditCard)
            if settingsDist < 1.5 then
                sleep = 0
                Config.DrawText3D('~INPUT_PICKUP~ - Bank Settings', Config.GetCreditCard)
                if IsControlJustReleased(0, 38) then
                    OpenSettingsMenu()
                end
            end

            for _, model in pairs(Config.ATMs) do
                local atmEntity = GetClosestObjectOfType(playerCoords, 2.0, GetHashKey(model), false, false, false)
                if atmEntity ~= 0 then
                    local atmCoords = GetEntityCoords(atmEntity)
                    local atmDist = #(playerCoords - atmCoords)
                    if atmDist < 1.5 then
                        sleep = 0
                        Config.DrawText3D('~INPUT_PICKUP~ - Open ATM', vector3(atmCoords.x, atmCoords.y, atmCoords.z + 1.0))
                        if IsControlJustReleased(0, 38) then
                            TriggerEvent('real-bank:OpenATMFunction')
                        end
                    end
                end
            end

            for _, v in pairs(Config.BankLocations) do
                local bankDist = #(playerCoords - v.Coords)
                if bankDist < 1.5 then
                    sleep = 0
                    Config.DrawText3D('~INPUT_PICKUP~ - Open Bank\n~INPUT_DETONATE~ - Open Society Bank', vector3(v.Coords.x, v.Coords.y, v.Coords.z))
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent('real-bank:OpenNormalBank')
                    elseif IsControlJustReleased(0, 47) then
                        TriggerEvent('real-bank:OpenSocietyBank')
                    end
                end
            end

            Citizen.Wait(sleep)
        end
    end)
end

function OpenBank()
    if Config.Drawtext == 'ox_target' then
        if GetResourceState('ox_target') ~= 'started' then
            local timeout = GetGameTimer() + 5000
            while GetResourceState('ox_target') ~= 'started' and GetGameTimer() < timeout do
                Citizen.Wait(200)
            end
        end

        CreateOxTargetInteractions()

        if Config.TargetFallback then
            StartFallbackInteractionThread()
        end

        return
    end

    StartFallbackInteractionThread()
end
