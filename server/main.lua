frameworkObject = nil
GetSQLTable = {}
StatusThing = nil
PlayerSource = 0

Citizen.CreateThread(function()
    frameworkObject, Config.Framework = GetCore()

    if not frameworkObject or not frameworkObject.Functions then
        print('[real-bank] Framework object not ready. Banking callbacks may fail until qbx_core is available.')
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    local data = ExecuteSql("SELECT * FROM `real_bank`")
    for k, v in pairs(data) do
        if v.transaction == nil then
            v.transaction = {}
        else
            v.transaction = json.decode(v.transaction)
        end
        if v.credit == nil then
            v.credit = {}
        else
            v.credit = json.decode(v.credit)
        end
        if v.info == nil then
            v.info = {}
        else
            v.info = json.decode(v.info)
        end
        if v.AccountUsed == nil then
            v.AccountUsed = {}
        else
            v.AccountUsed = json.decode(v.AccountUsed)
        end
    end
    GetSQLTable = data
end)

Citizen.CreateThread(function()
    RegisterCallback("real-bank:GetPlayerData", function(source, cb)
        local src = source
        PlayerSource = src
        local PlayerIdent = GetIdentifier(src)
        local PlayerMoney = GetPlayerMoneyOnline("bank", src)
        local PlayersCash = GetPlayerMoneyOnline("cash", src)
        local dcpfp = GetDiscordAvatar(src)
        local data = ExecuteSql("SELECT * FROM `real_bank` WHERE `identifier` = '"..PlayerIdent.."'")
        local transferplayersdata = GetPlayers()
        
        local currenttime = GetCurrentDate()

        if #data > 0 then
            local accountusedtable = json.decode(data[1].AccountUsed)
            local getcredittable = json.decode(data[1].credit)
            local getdatefromdata = getcredittable.creditlastdate

            if accountusedtable.loginlimit > 0 then
                if accountusedtable.withdrawlimit > 0 then
                    if Config.CreditSystem == true then
                        if getcredittable.debt > 0 then
                            if getdatefromdata ~= 0 or getdatefromdata ~= '' or getdatefromdata ~= "" or getdatefromdata ~= nil then
                                if tostring(currenttime) > tostring(getdatefromdata) then
                                    TriggerEvent('real-bank:PayCreditDebts')
                                    Citizen.Wait(100)
                                    if StatusThing == true then
                                        local a = json.decode(data[1].info)
                                        local b = json.decode(data[1].credit)
                                        data[1].info = a
                                        data[1].credit = b
                                        if tostring(a.playerpfp) ~= tostring(dcpfp) then
                                            a.playerpfp = dcpfp
                                            ExecuteSql("UPDATE `real_bank` SET `info` = '"..json.encode(data[1].info).."' WHERE `identifier` = '"..PlayerIdent.."' ")
                                        end
                                        DataTable = {
                                            data = data,
                                            PlayerMoney = tonumber(PlayerMoney),
                                            PlayerCash = tonumber(PlayersCash),
                                            transferlist = transferplayersdata
                                        }
                                        cb(DataTable)
                                    end
                                else
                                    local a = json.decode(data[1].info)
                                    local b = json.decode(data[1].credit)
                                    data[1].info = a
                                    data[1].credit = b
                                    if tostring(a.playerpfp) ~= tostring(dcpfp) then
                                        a.playerpfp = dcpfp
                                        ExecuteSql("UPDATE `real_bank` SET `info` = '"..json.encode(data[1].info).."' WHERE `identifier` = '"..PlayerIdent.."' ")
                                    end
                                    DataTable = {
                                        data = data,
                                        PlayerMoney = tonumber(PlayerMoney),
                                        PlayerCash = tonumber(PlayersCash),
                                        transferlist = transferplayersdata
                                    }
                                    cb(DataTable)
                                end
                            end
                        else
                            local a = json.decode(data[1].info)
                            local b = json.decode(data[1].credit)
                            data[1].info = a
                            data[1].credit = b
                            if tostring(a.playerpfp) ~= tostring(dcpfp) then
                                a.playerpfp = dcpfp
                                ExecuteSql("UPDATE `real_bank` SET `info` = '"..json.encode(data[1].info).."' WHERE `identifier` = '"..PlayerIdent.."' ")
                            end
                            DataTable = {
                                data = data,
                                PlayerMoney = tonumber(PlayerMoney),
                                PlayerCash = tonumber(PlayersCash),
                                transferlist = transferplayersdata
                            }
                            cb(DataTable)
                        end
                    else
                        local a = json.decode(data[1].info)
                        local b = json.decode(data[1].credit)
                        data[1].info = a
                        data[1].credit = b
        
                        if tostring(a.playerpfp) ~= tostring(dcpfp) then
                            a.playerpfp = dcpfp
                            ExecuteSql("UPDATE `real_bank` SET `info` = '"..json.encode(data[1].info).."' WHERE `identifier` = '"..PlayerIdent.."' ")
                        end
        
                        DataTable = {
                            data = data,
                            PlayerMoney = tonumber(PlayerMoney),
                            PlayerCash = tonumber(PlayersCash),
                            transferlist = transferplayersdata
                        }
                        cb(DataTable)
                    end
                else
                    Config.Notification(Config.Language['change_password_to_access'], 'error', true, src)
                end
            else
                Config.Notification(Config.Language['change_password_to_access'], 'error', true, src)
            end
        end
    end)

    RegisterCallback("real-bank:GetBills", function(source, cb)
        local src = source
        local identity = GetIdentifier(src)
        local data = ExecuteSql("SELECT * FROM `phone_invoices` WHERE `citizenid` = '"..identity.."'")
        if next(data) then
            cb(data)
        else
            cb(false)
        end
    end)

    frameworkObject.Functions.CreateCallback("real-bank:ATMLoginAnotherAccount", function(source, cb, getdata)
        local src = source
        local targetiban = getdata.iban
        local data = ExecuteSql("SELECT * FROM `real_bank` WHERE `iban` = '"..targetiban.."'")
        if data and data[1] then
            local targetidentity = data[1].identifier
            local targetinfo = json.decode(data[1].info)
            local targettransaction = json.decode(data[1].transaction)
            local accountusedtable = json.decode(data[1].AccountUsed)
            local targetaccountmoney = GetPlayerMoneyOffline(targetidentity)

            if tonumber(getdata.password) == tonumber(data[1].password) then
                if accountusedtable.loginlimit ~= 0 then
                    DataTable = {
                        infodata = targetinfo,
                        targetmoney = targetaccountmoney,
                        transaction = targettransaction,
                        loginlimit = accountusedtable.loginlimit,
                        withdrawlimit = accountusedtable.withdrawlimit,
                        iban = targetiban
                    }
                    cb(DataTable)
                    accountusedtable.loginlimit = accountusedtable.loginlimit - 1
                    ExecuteSql("UPDATE `real_bank` SET `AccountUsed` = '"..json.encode(accountusedtable).."' WHERE `identifier` = '"..targetidentity.."'")
                else
                    Config.Notification(Config.Language['cant_hack_anymore'], 'error', true, src)
                end
            else
                TriggerClientEvent('real-bank:Close', src)
                Config.Notification(Config.Language['wrong_password'], 'error', true, src)
            end
        else
            TriggerClientEvent('real-bank:Close', src)
            Config.Notification(Config.Language['wrong_password'], 'error', true, src)
        end
    end)
end)

RegisterNetEvent("real-bank:CreateAccount", function(password)
    local src = source
    local ident = GetIdentifier(src)
    local DiscordAvatar = GetDiscordAvatar(src)
    local CreditTable = {}

    if Config.CreditSystem == true then
        CreditTable = {
            playercreditpoint = Config.StartCreditPoint,
            activecredit = '',
            creditlastdate = 0,
            debt = 0,
        }
    end

    local Player = frameworkObject.Functions.GetPlayer(src)
    if not Player then
        return
    end

    if AccountExists(ident) then
        Config.Notification(Config.Language['already_have_account'], 'error', true, src)
        return
    end

    local uniqueIban = GenerateUniqueIBAN()
    CreateAccount = {
        identifier = ident,
        info = {
            playername = GetName(src),
            playerpfp = DiscordAvatar
        },
        credit = CreditTable,
        transaction = {},
        iban = uniqueIban,
        password = password,
        AccountUsed = {
            loginlimit = Config.LoginLimit,
            withdrawlimit = Config.WithdrawLimit
        }
    }

    local insertQuery = ("INSERT INTO `real_bank` (`identifier`, `info`, `credit`, `transaction`, `iban`, `password`, `AccountUsed`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')"):format(
        SqlEscape(CreateAccount.identifier),
        SqlEscape(json.encode(CreateAccount.info)),
        SqlEscape(json.encode(CreateAccount.credit)),
        SqlEscape(json.encode(CreateAccount.transaction)),
        SqlEscape(CreateAccount.iban),
        SqlEscape(CreateAccount.password),
        SqlEscape(json.encode(CreateAccount.AccountUsed))
    )

    ExecuteSql(insertQuery)
    Config.Notification(Config.Language['successfully_created_account'], 'success', true, src)
    Citizen.Wait(200)
    table.insert(GetSQLTable, CreateAccount)
    Citizen.Wait(100)
end)

RegisterNetEvent('real-bank:ATMLoginOwnAccount', function(password)
    local src = source
    local PlayerIdent = GetIdentifier(src)
    local data = ExecuteSql("SELECT `password` FROM `real_bank` WHERE `identifier` = '"..PlayerIdent.."'")
    if data[1] then
        if tonumber(password) == tonumber(data[1].password) then
            TriggerClientEvent('real-bank:OpenBank', src)
        else
            Config.Notification(Config.Language['wrong_password'], 'error', true, src)
        end
    end
end)

RegisterNetEvent('real-bank:ChangePassword', function(newpassword)
    local ident = GetIdentifier(source)
    local data = ExecuteSql("SELECT `identifier` FROM `real_bank` WHERE `identifier` = '" .. ident .. "'")
    
    if data[1] then
        ExecuteSql("UPDATE `real_bank` SET `password` = '" .. newpassword .. "' WHERE `identifier` = '" .. ident .. "'")
    else
        print('No data found for identifier')
    end
end)

RegisterNetEvent('real-bank:CheckAccountExistens', function(data)
    local src = tonumber(source)
    if not src or src <= 0 then
        return
    end

    local ident = GetIdentifier(src)
    local Account = AccountExists(ident)

    if Account then
        if data then
            TriggerClientEvent('real-bank:CheckAccountExistensResult', src, true, data)
        else
            TriggerClientEvent('real-bank:CheckAccountExistensResult', src, true, nil)
        end
    else 
        if data then
            TriggerClientEvent('real-bank:CheckAccountExistensResult', src, false, data)
        else
            TriggerClientEvent('real-bank:CheckAccountExistensResult', src, false, nil)
        end
    end
end)

RegisterNetEvent('real-bank:CreditConfirm', function(data)
    local src = source
    local ident = GetIdentifier(src)
    local sqldata = ExecuteSql("SELECT `credit` FROM `real_bank` WHERE `identifier` = '"..ident.."'")
    local a = json.decode(sqldata[1].credit)
    if a.credid == '' or a.cerdid == "" or a.credid == nil then
        if Config.RequireCreditPoint then
            if a.playercreditpoint > data.credreq then
                a.playercreditpoint = a.playercreditpoint - data.credreq
                NewCreditTable = {
                    playercreditpoint = a.playercreditpoint,
                    debt = data.credprice*data.credpaybackpercent,
                    activecredit = data.credid,
                    creditlastdate = os.date('%d.%m.%Y', os.time() + tonumber(data.creddate) * 7 * 24 * 60 * 60)
                }
                ExecuteSql("UPDATE `real_bank` SET `credit` = '"..json.encode(NewCreditTable).."' WHERE `identifier` = '"..ident.."'")
                RemoveAddBankMoneyOnline('add', tonumber(data.credprice), src)
            else
                Config.Notification(Config.Language['not_enough_cp'], 'error', true, src)
            end
        else
            a.playercreditpoint = a.playercreditpoint - data.credreq
            NewCreditTable = {
                playercreditpoint = a.playercreditpoint,
                debt = data.credprice*data.credpaybackpercent,
                activecredit = data.credid,
                creditlastdate = os.date('%d.%m.%Y', os.time() + tonumber(data.creddate) * 7 * 24 * 60 * 60)
            }
            ExecuteSql("UPDATE `real_bank` SET `credit` = '"..json.encode(NewCreditTable).."' WHERE `identifier` = '"..ident.."'")
            RemoveAddBankMoneyOnline('add', tonumber(data.credprice), src)
        end
    else
        Config.Notification(Config.Language['already_active_cp'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:PayCreditDebts', function()
    local ident = GetIdentifier(PlayerSource)
    local data = ExecuteSql("SELECT `credit` FROM `real_bank` WHERE `identifier` = '"..ident.."'")
    local GetPlayerMoney = GetPlayerMoneyOnline('bank', PlayerSource)
    local a = json.decode(data[1].credit)
    if a.debt > 0 then
        if GetPlayerMoney > tonumber(a.debt) then
            NewCreditTable = {
                playercreditpoint =  a.playercreditpoint,
                activecredit = '',
                creditlastdate = 0,
                debt = 0,
            }
            ExecuteSql("UPDATE `real_bank` SET `credit` = '"..json.encode(NewCreditTable).."' WHERE `identifier` = '"..ident.."'")
            RemoveAddBankMoneyOnline('remove', tonumber(a.debt), PlayerSource)
            StatusThing = true
        else
            StatusThing = false
            Config.Notification(Config.Language['no_money_to_pay_debts'], 'error', true, source)
        end
    end
end)

RegisterNetEvent('real-bank:PayBills', function(id, amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment then
        return
    end

    if Player.PlayerData.money.bank >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        ExecuteSql("DELETE FROM `phone_invoices` WHERE `id` = '"..id.."'")
        TriggerClientEvent('real-bank:RefreshBillsUI', src)
    else
        Config.Notification(Config.Language['no_money_to_pay_bills'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:DepositMoney', function(amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then
        return
    end

    if Player.PlayerData.money.cash >= payment then
        Player.Functions.AddMoney('bank', payment)
        Player.Functions.RemoveMoney('cash', payment)
        SendLog(src, nil, nil, 'Deposit', payment, 'discord')
    else
        Config.Notification(Config.Language['not_enough_money'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:WithdrawMoney', function(amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then
        return
    end

    if Player.PlayerData.money.bank >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        Player.Functions.AddMoney('cash', payment)
        SendLog(src, nil, nil, 'Withdraw', payment, 'discord')
    else
        Config.Notification(Config.Language['not_enough_money'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:WithdrawFastAction', function(amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then
        return
    end

    if Player.PlayerData.money.bank >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        Player.Functions.AddMoney('cash', payment)
        SendLog(src, nil, nil, 'Withdraw', payment, 'discord')
    else
        Config.Notification(Config.Language['not_enough_money'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:DepositFastAction', function(amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then
        return
    end

    if Player.PlayerData.money.cash >= payment then
        Player.Functions.AddMoney('bank', payment)
        Player.Functions.RemoveMoney('cash', payment)
        SendLog(src, nil, nil, 'Deposit', payment, 'discord')
    else
        Config.Notification(Config.Language['not_enough_money'], 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:WithdrawHackedAccount', function(getdata)
    local src = source
    local targetiban = getdata.iban
    local data = ExecuteSql("SELECT * FROM `real_bank` WHERE `iban` = '"..targetiban.."'")
    if data and data[1] then
        local targetidentity = data[1].identifier
        local accountusedtable = json.decode(data[1].AccountUsed)
        local targetplayermoney = GetPlayerMoneyOffline(targetidentity)
        local amountToWithdraw = tonumber(getdata.amount)
        if amountToWithdraw and amountToWithdraw > 0 then
            if tonumber(targetplayermoney) >= amountToWithdraw then
                if accountusedtable.withdrawlimit >= amountToWithdraw then
                    RemoveBankMoneyOffline(targetidentity, amountToWithdraw)
                    local Player = frameworkObject.Functions.GetPlayer(src)
                    Player.Functions.AddMoney("cash", amountToWithdraw)
                    accountusedtable.withdrawlimit = accountusedtable.withdrawlimit - amountToWithdraw
                    ExecuteSql("UPDATE `real_bank` SET `AccountUsed` = '"..json.encode(accountusedtable).."' WHERE `identifier` = '"..targetidentity.."'")
                else
                    Config.Notification("You cannot withdraw that much from this hacked account", 'error', true, src)
                end
            else
                Config.Notification(Config.Language['not_enough_money'], 'error', true, src)
            end
        end
    else
        print("IBAN not found")
    end
end)

RegisterNetEvent('real-bank:TransferMoney', function(iban, amount)
    local src = source
    local transferAmount = tonumber(amount)

    if not transferAmount or transferAmount <= 0 then
        return
    end

    local data = ExecuteSql("SELECT * FROM `real_bank` WHERE `iban` = '"..iban.."'")

    for _, v in pairs(data) do
        if tonumber(v.iban) == tonumber(iban) then
            local Player = frameworkObject.Functions.GetPlayer(src)
            local senderplayername = GetName(src)
            if not Player then
                return
            end

            if Player.PlayerData.money.bank >= transferAmount then
                local targetplayersource = frameworkObject.Functions.GetSource(v.identifier)
                if tonumber(targetplayersource) ~= 0 then
                    local targetPlayer = frameworkObject.Functions.GetPlayer(targetplayersource)
                    local targetplayername = GetName(targetplayersource)

                    if targetPlayer then
                        Player.Functions.RemoveMoney('bank', transferAmount)
                        targetPlayer.Functions.AddMoney('bank', transferAmount)
                        SendLog(src, nil, targetplayername, 'Transfer', transferAmount, 'discord')
                        SendLog(targetplayersource, senderplayername, nil, 'Received', transferAmount, 'discord')
                    end
                else
                    local getplayersname = ExecuteSql("SELECT `charinfo` FROM `players` WHERE `citizenid` = '"..v.identifier.."'")
                    local b = json.decode(getplayersname[1].charinfo)
                    local targetName = b.firstname .. " " .. b.lastname
                    Player.Functions.RemoveMoney('bank', transferAmount)
                    AddBankMoneyOffline(v.identifier, transferAmount)
                    SendLog(src, nil, targetName, 'Transfer', transferAmount, 'discord')
                    SendOfflineLog(src, v.identifier, targetName, senderplayername, nil, 'Received', transferAmount, 'discord')
                end
            else
                Config.Notification(Config.Language['transfer_no_money'], 'error', true, src)
            end
        end
    end
end)

function GetCurrentDate()
    local currentTime = os.time()
    local formattedDate = os.date("%d.%m.%Y", currentTime)
    return formattedDate
end

function GetIdentifier(source)
    local Player = frameworkObject.Functions.GetPlayer(tonumber(source))
    if Player then
        return Player.PlayerData.citizenid
    else
        return "0"
    end
end

function GetName(source)
    local Player = frameworkObject.Functions.GetPlayer(tonumber(source))
    if Player then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    else
        return "0"
    end
end

function SqlEscape(value)
    if value == nil then
        return ''
    end

    local escaped = tostring(value)
    escaped = escaped:gsub("\\", "\\\\")
    escaped = escaped:gsub("'", "''")
    return escaped
end

function AccountExists(identifier)
    local ident = SqlEscape(identifier)
    local result = ExecuteSql("SELECT `identifier` FROM `real_bank` WHERE `identifier` = '"..ident.."' LIMIT 1")
    return result and result[1] ~= nil
end

function GenerateUniqueIBAN()
    for _ = 1, 100 do
        local candidate = math.random(1000, 9999)
        local result = ExecuteSql("SELECT `iban` FROM `real_bank` WHERE `iban` = '"..candidate.."' LIMIT 1")
        if not result or not result[1] then
            return candidate
        end
    end

    return math.random(1000, 9999)
end

function GetPlayerAccount(identifier)
    local ident = identifier
    for k, v in pairs(GetSQLTable) do
        if v.identifier == ident then
            return v, k
        end
    end
    return false
end

function RegisterCallback(name, cbFunc, data)
    while not frameworkObject do
        Citizen.Wait(0)
    end

    frameworkObject.Functions.CreateCallback(
        name,
        function(source, cb, data)
            cbFunc(source, cb)
        end
    )
end

function GetPlayerMoneyOffline(identifier)
    local result = ExecuteSql("SELECT money FROM players WHERE citizenid = '"..identifier.."'")
    local targetMoney = json.decode(result[1].money)
    return targetMoney.bank
end

function RemoveBankMoneyOffline(identifier, payment)
    local result = ExecuteSql("SELECT money FROM players WHERE citizenid = '"..identifier.."'")
    local targetMoney = json.decode(result[1].money)
    targetMoney.bank = targetMoney.bank - payment
    ExecuteSql("UPDATE players SET money = '"..json.encode(targetMoney).."' WHERE citizenid = '"..identifier.."'")
end

function AddBankMoneyOffline(identifier, payment)
    local result = ExecuteSql("SELECT money FROM players WHERE citizenid = '"..identifier.."'")
    local targetMoney = json.decode(result[1].money)
    targetMoney.bank = targetMoney.bank + payment
    ExecuteSql("UPDATE players SET money = '"..json.encode(targetMoney).."' WHERE citizenid = '"..identifier.."'")
end

function RemoveAddBankMoneyOnline(type, amount, id)
    local Player = frameworkObject.Functions.GetPlayer(id)
    if type == 'add' then
        Player.Functions.AddMoney('bank', tonumber(amount))
    elseif type == 'remove' then
        Player.Functions.RemoveMoney('bank', tonumber(amount))
    end
end

function GetPlayerMoneyOnline(type, id)
    local Player = frameworkObject.Functions.GetPlayer(id)
    if not Player then
        return 0
    end

    if type == 'bank' then
        return tonumber(Player.PlayerData.money.bank)
    elseif type == 'cash' then
        return tonumber(Player.PlayerData.money.cash)
    end
end

function GetPlayers()
    local resulttable = {}
    local data = ExecuteSql("SELECT * FROM `real_bank`")
    if data or data[1] then 
        for k, v in pairs(data) do
            local a = json.decode(v.info)
            table.insert(resulttable, {
                id = k,
                pp = a.playerpfp,
                playername = a.playername,
                iban = v.iban
            })
        end
        return resulttable
    end
end

function GetPassword(iban)
    local data = ExecuteSql("SELECT `password` FROM `real_bank` WHERE `iban` = '"..iban.."'")
    if #data > 0 then
        local Password = tostring(data[1].password)
        return Password
    else
        print("Data not found")
    end
end

function GetIBAN(source, identifier, IsSoruce)
    if IsSoruce then
        local source = source
        local ident = GetIdentifier(source)
        local data = ExecuteSql("SELECT `iban` FROM `real_bank` WHERE `identifier` = '"..ident.."'")
        local IBAN = json.decode(data[1].iban)
        return IBAN
    else
        local data = ExecuteSql("SELECT `iban` FROM `real_bank` WHERE `identifier` = '"..identifier.."'")
        local IBAN = json.decode(data[1].iban)
        return IBAN
    end
end

function GiveCredit(playersource, amount)
    local source = playersource
    local ident = GetIdentifier(source)
    local data = ExecuteSql("SELECT `credit` FROM `real_bank` WHERE `identifier` = '"..ident.."'")
    local Credit = json.decode(data[1].credit)

    if #data > 0 then
        Credit.playercreditpoint = Credit.playercreditpoint + amount
        ExecuteSql("UPDATE `real_bank` SET `credit` = '"..json.encode(Credit).."' WHERE `identifier` = '"..ident.."'")
    else
        print("Data not found")
    end
end

function SendLog(playersource, received, sendedto, type, amount, pp)
    local source = playersource
    local ident = GetIdentifier(source)
    local GetPlayerName = GetName(source)
    local DiscordAvatar = GetDiscordAvatar(source)
    local data = ExecuteSql("SELECT `transaction` FROM `real_bank` WHERE `identifier` = '"..ident.."'")
    local Transaction = json.decode(data[1].transaction)

    if #data > 0 then
        if received == nil then
            received = ''
        end
        if sendedto == nil then
            sendedto = ''
        end
        if pp == 'discord' then
            pp = DiscordAvatar
        end

        TableID = #Transaction + 1
        
        table.insert(Transaction, {
            id = TableID,
            name = GetPlayerName,
            received = received,
            sendedto = sendedto,
            type = type,
            amount = amount,
            pp = pp,
            date = GetCurrentDate(),
        })
        ExecuteSql("UPDATE `real_bank` SET `transaction` = '"..json.encode(Transaction).."' WHERE `identifier` = '"..ident.."'")
        TriggerClientEvent('real-bank:UpdateUITransaction', source)
    else
        print("Data not found")
    end
end

function SendOfflineLog(sendersource, identifier, playername, received, sendedto, type, amount, pp)
    local source = sendersource
    local data = ExecuteSql("SELECT `transaction` FROM `real_bank` WHERE `identifier` = '"..identifier.."'")
    local Transaction = json.decode(data[1].transaction)
    local DiscordAvatar = GetDiscordAvatar(source)

    if #data > 0 then
        if received == nil then
            received = ''
        end
        if sendedto == nil then
            sendedto = ''
        end
        if pp == 'discord' and sendersource ~= 0 or sendersource ~= nil then
            pp = DiscordAvatar
        end

        TableID = #Transaction + 1
        
        table.insert(Transaction, {
            id = TableID,
            name = playername,
            received = received,
            sendedto = sendedto,
            type = type,
            amount = amount,
            pp = pp,
            date = GetCurrentDate(),
        })
        ExecuteSql("UPDATE `real_bank` SET `transaction` = '"..json.encode(Transaction).."' WHERE `identifier` = '"..identifier.."'")
    else
        print("Data not found")
    end
end

exports('GiveCredit', function(source, amount)
    GiveCredit(source, amount)
end)

exports('SendLog', function(source, received, sendedto, type, amount, pp)
    SendLog(source, received, sendedto, type, amount, pp)
end)

exports('SendOfflineLog', function(sendersource, identifier, playername, received, sendedto, type, amount, pp)
    SendOfflineLog(sendersource, identifier, playername, received, sendedto, type, amount, pp)
end)

exports('GetPassword', function(iban)
    GetPassword(iban)
end)

exports('GetIBAN', function(source, identifier, IsSoruce)
    GetIBAN(source, identifier, IsSoruce)
end)

function ExecuteSql(query)
    local IsBusy = true
    local result = nil
    if Config.MySQL == "oxmysql" then
        if MySQL == nil then
            exports.oxmysql:execute(
                query,
                function(data)
                    result = data
                    IsBusy = false
                end
            )
        else
            MySQL.query(
                query,
                {},
                function(data)
                    result = data
                    IsBusy = false
                end
            )
        end
    elseif Config.MySQL == "ghmattimysql" then
        exports.ghmattimysql:execute(
            query,
            {},
            function(data)
                result = data
                IsBusy = false
            end
        )
    elseif Config.MySQL == "mysql-async" then
        MySQL.Async.fetchAll(
            query,
            {},
            function(data)
                result = data
                IsBusy = false
            end
        )
    end
    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

RegisterCallback("real-bank:GetSocietyMoney", function(source, cb, society)
    local amount = 0
    local status = pcall(function()
        amount = exports['qbx_management']:GetAccount(society)
    end)
    if not status then 
        local status2 = pcall(function()
            amount = exports['qb-management']:GetAccount(society)
        end)
        if not status2 then cb(false) return end
    end
    cb(amount or 0)
end)

RegisterNetEvent('real-bank:DepositSociety', function(society, amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then return end
    
    if (Player.PlayerData.job.name ~= society and Player.PlayerData.gang.name ~= society) then return end
    if (not Player.PlayerData.job.isboss and not Player.PlayerData.gang.isboss) then return end

    if Player.PlayerData.money.bank >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        if GetResourceState('qbx_management') == 'started' then
            exports['qbx_management']:AddMoney(society, payment)
        elseif GetResourceState('qb-management') == 'started' then
            exports['qb-management']:AddMoney(society, payment)
        end
        Config.Notification(Config.Language['successfully_deposited'] or 'Successfully deposited', 'success', true, src)
    else
        Config.Notification(Config.Language['not_enough_money'] or 'Not enough money', 'error', true, src)
    end
end)

RegisterNetEvent('real-bank:WithdrawSociety', function(society, amount)
    local src = source
    local payment = tonumber(amount)
    local Player = frameworkObject.Functions.GetPlayer(src)

    if not Player or not payment or payment <= 0 then return end
    
    if (Player.PlayerData.job.name ~= society and Player.PlayerData.gang.name ~= society) then return end
    if (not Player.PlayerData.job.isboss and not Player.PlayerData.gang.isboss) then return end

    local accMoney = 0
    if GetResourceState('qbx_management') == 'started' then
        accMoney = exports['qbx_management']:GetAccount(society)
    elseif GetResourceState('qb-management') == 'started' then
        accMoney = exports['qb-management']:GetAccount(society)
    end

    if accMoney and accMoney >= payment then
        if GetResourceState('qbx_management') == 'started' then
            exports['qbx_management']:RemoveMoney(society, payment)
        elseif GetResourceState('qb-management') == 'started' then
            exports['qb-management']:RemoveMoney(society, payment)
        end
        Player.Functions.AddMoney('bank', payment)
        Config.Notification(Config.Language['successfylly_withdrawed'] or 'Successfully withdrawed', 'success', true, src)
    else
        Config.Notification('Society does not have enough money', 'error', true, src)
    end
end)
