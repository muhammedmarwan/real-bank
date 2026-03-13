frameworkObject = false
response = false

Citizen.CreateThread(function()
    frameworkObject, Config.Framework = GetCore()
    OpenBank()
    CreateBlips()

    while not response do
        Citizen.Wait(0)
    end

    Citizen.Wait(500)
    SendNUIMessage({
        action = 'Setup',
        first = Config.FirstFastAction,
        second = Config.SecondFastAction,
        third = Config.ThirdFastAction,
        language = Config.Language,
        invoicetheme = Config.InvoiceTheme,
        cardstyle = Config.CardStyle,
        credittable = Config.AvailableCredits,
        requirecreditpoint = Config.RequireCreditPoint,
        creditsystem = Config.CreditSystem,
    })
end)

RegisterNUICallback('GetResponse', function(data, cb)
    response = true
    if cb then
        cb("ok")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        SendNUIMessage({
            action = "SendResponse",
        })
        if response then
            return
        end
    end
end)

function CreateBlips()
    for k, v in pairs(Config.BankLocations) do
        blip = AddBlipForCoord(v.Coords.x, v.Coords.y, v.Coords.z)
        SetBlipSprite(blip, v.BlipType)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, v.BlipScale)
        SetBlipColour(blip, v.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v.Blipname)
        EndTextCommandSetBlipName(blip)
    end
end

RegisterNetEvent('real-bank:CheckAccountExistensResult', function(result, data)
    if data then
        local action = type(data) == 'table' and data.value or data

        if action == 'Get' then
            if not result then
                SendNUIMessage({
                    action = 'OpenCreatePasswordScreen'
                })
                SetNuiFocus(true, true)
            else
                Config.Notification(Config.Language['already_have_account'], 'error', false)
            end
        elseif action == 'Change' then
            if result then
                SendNUIMessage({
                    action = 'OpenChangePasswordScreen'
                })
                SetNuiFocus(true, true)
            else
                Config.Notification(Config.Language['no_account'], 'error', false)
            end
        end
    else
        if result then
            OpenBankUI()
        else
            SendNUIMessage({
                action = 'OpenCreatePasswordScreen'
            })
            SetNuiFocus(true, true)
        end
    end
end)

function OpenATM()
    SendNUIMessage({
        action = 'OpenATM',
        isATM = true
    })
    SetNuiFocus(true, true)
end

function OpenBankUI()
    local data = Callback('real-bank:GetPlayerData')
    if not data or not data.data then
        Config.Notification('Bank data could not be loaded. Try again.', 'error', false)
        return
    end

    local billsdata = Callback('real-bank:GetBills')
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OpenBank',
        data = data.data,
        playermoney = data.PlayerMoney,
        playercash = data.PlayerCash,
        billsframe = 'qb',
        billsdata = billsdata,
        transferlist = data.transferlist
    })
end

function OpenBankAnotherAccount(pidata)
    local data = Callback('real-bank:ATMLoginAnotherAccount', pidata)

    if data then
        SendNUIMessage({
            action = 'OpenAnotherAccount',
            infodata = data.infodata,
            targetmoney = data.targetmoney,
            transaction = data.transaction,
            iban = data.iban,
            loginlimit = data.loginlimit,
            withdrawlimit = data.withdrawlimit,
        })
        SetNuiFocus(true, true)
    end
end

function SendLog(received, sendedto, type, amount, pp)
    TriggerServerEvent('real-bank:SendLog', received, sendedto, type, amount, pp)
end

RegisterNetEvent('real-bank:OpenATMFunction')
AddEventHandler('real-bank:OpenATMFunction', function()
    OpenATM()
end)

RegisterNetEvent('real-bank:OpenNormalBank')
AddEventHandler('real-bank:OpenNormalBank', function()
    TriggerServerEvent('real-bank:CheckAccountExistens', nil)
end)


RegisterNetEvent('real-bank:UpdateUITransaction')
AddEventHandler('real-bank:UpdateUITransaction', function()
    local data = Callback('real-bank:GetPlayerData')
    SendNUIMessage({
        action = 'UpdateTransaction',
        data = data.data
    })
end)

RegisterNetEvent('real-bank:BankSettings')
AddEventHandler('real-bank:BankSettings', function(data)
    local action = type(data) == 'table' and data.value or data

    if action == 'Get' or action == 'Change' then
        TriggerServerEvent('real-bank:CheckAccountExistens', action)
    end
end)

RegisterNetEvent('real-bank:RefreshBillsUI')
AddEventHandler('real-bank:RefreshBillsUI', function()
    local billsdata = Callback('real-bank:GetBills')
    local playerdata = frameworkObject.Functions.GetPlayerData()
    local playercurrentmoney = playerdata.money.bank
    SendNUIMessage({
        action = 'RefreshBills',
        billsframe = 'qb',
        billsdata = billsdata,
        playermoney = playercurrentmoney,
    })
end)

RegisterNetEvent('real-bank:OpenBank')
AddEventHandler('real-bank:OpenBank', function()
    OpenBankUI()
end)

RegisterNetEvent('real-bank:Close')
AddEventHandler('real-bank:Close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('CreatePassword', function(data, cb)
    TriggerServerEvent("real-bank:CreateAccount", data)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('ChangePassword', function(data, cb)
    TriggerServerEvent("real-bank:ChangePassword", data)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('ConfirmCredit', function(data, cb)
    TriggerServerEvent('real-bank:CreditConfirm', data)
end)

RegisterNUICallback('PayDebts', function(data, cb)
    TriggerServerEvent('real-bank:PayCreditDebts')
end)

RegisterNUICallback('PayBill', function(data, cb)
    TriggerServerEvent('real-bank:PayBills', data.id, data.amount)
end)

RegisterNUICallback('DepositMoney', function(data, cb)
    TriggerServerEvent('real-bank:DepositMoney', data)
end)

RegisterNUICallback('WithdrawMoney', function(data, cb)
    TriggerServerEvent('real-bank:WithdrawMoney', data)
end)

RegisterNUICallback('ATMLoginToOwnAccount', function(data, cb)
    TriggerServerEvent('real-bank:ATMLoginOwnAccount', data)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('ATMLoginAnotherAccount', function(data, cb)
    SetNuiFocus(false, false)
    OpenBankAnotherAccount(data)
end)

RegisterNUICallback('WithdrawHackedAccount', function(data, cb)
    TriggerServerEvent('real-bank:WithdrawHackedAccount', data)
end)

RegisterNUICallback('WithdrawFastAction', function(data, cb)
    TriggerServerEvent('real-bank:WithdrawFastAction', data)
end)

RegisterNUICallback('DepositFastAction', function(data, cb)
    TriggerServerEvent('real-bank:DepositFastAction', data)
end)

RegisterNUICallback('TransferMoney', function(data, cb)
    TriggerServerEvent('real-bank:TransferMoney', data.iban, data.amount)
end)

RegisterNUICallback('Logout', function(data, cb)
    SetNuiFocus(false, false)
end)

RegisterNUICallback('CloseBankUI', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'CloseBankUI'
    })
end)

RegisterNUICallback('CloseATM', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'CloseATMUI'
    })
end)

function Callback(name, payload)
    local data = nil
    if frameworkObject then
        frameworkObject.Functions.TriggerCallback(name, function(returndata)
            data = returndata
        end, payload)

        local timeout = GetGameTimer() + 5000
        while data == nil and GetGameTimer() < timeout do
            Citizen.Wait(0)
        end

        if data == nil then
            print(('[real-bank] Callback timeout: %s'):format(name))
            return false
        end
    end

    return data
end

RegisterNetEvent('real-bank:OpenSocietyBank', function()
    local playerData = frameworkObject.Functions.GetPlayerData()
    local jobName, jobLabel, isBoss
    
    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        if playerData.job and playerData.job.isboss then
            jobName = playerData.job.name
            jobLabel = playerData.job.label
            isBoss = true
        elseif playerData.gang and playerData.gang.isboss then
            jobName = playerData.gang.name
            jobLabel = playerData.gang.label
            isBoss = true
        end
    end

    if not isBoss then
        Config.Notification('You are not a boss!', 'error', false)
        return
    end

    local money = Callback('real-bank:GetSocietyMoney', jobName)
    if money == false then
        Config.Notification('Society account not found!', 'error', false)
        return
    end

    lib.registerContext({
        id = 'society_bank_menu',
        title = jobLabel .. ' Society Account',
        options = {
            {
                title = 'Balance',
                description = '$' .. tostring(money),
                icon = 'building-columns'
            },
            {
                title = 'Deposit Money',
                icon = 'arrow-up',
                onSelect = function()
                    local input = lib.inputDialog('Deposit Society Money', {'Amount'})
                    if input and input[1] then
                        TriggerServerEvent('real-bank:DepositSociety', jobName, tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Withdraw Money',
                icon = 'arrow-down',
                onSelect = function()
                    local input = lib.inputDialog('Withdraw Society Money', {'Amount'})
                    if input and input[1] then
                        TriggerServerEvent('real-bank:WithdrawSociety', jobName, tonumber(input[1]))
                    end
                end
            }
        }
    })
    lib.showContext('society_bank_menu')
end)
