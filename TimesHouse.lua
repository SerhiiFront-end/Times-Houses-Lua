local sampev = require'samp.events'
local inicfg = require 'inicfg'
local effil = require('effil')
local encoding = require('encoding')
local u8 = encoding.UTF8
encoding.default = 'CP1251'

local direct = "\\times.ini"
local mainIni = inicfg.load(nil, direct)

local TextDrawId = 0
local active = false

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(200) end

	takeServerIP, takeServerPort = sampGetCurrentServerAddress()
	if takeServerIP == "185.169.134.84" then
		sampAddChatMessage('Скрипт для записи времени домов загружен...{32CD32}Автор: {9A2EFE}Lopez', 0xFFf5deb3)
	else
		thisScript():unload()
	end
	sampRegisterChatCommand('gethouse', getinfo)
	sampRegisterChatCommand('sdm', MessagetoDiscord)
	sampRegisterChatCommand('sethouse', setinfo)
	if mainIni == nil then
		mainIni = {
			times = {},
			TextDrawId = 0
		}
		inicfg.save(mainIni,direct)
	end
	if mainIni.times.TextDrawId == 0 or mainIni.times.TextDrawId == nil or mainIni.times.TextDrawId == '' then
		GOStr()
	end
end
function MessagetoDiscord(arg)
	arg1, arg2 = string.match(arg, '(%d+) (%d+)')
	if arg1 == nil or arg1 == '' then
		sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Введите номер дома, пробел и затем время на него(без ":00").', 0xFFf5deb3)
	else
		perevod = arg2 + 0
		if perevod >= 0 and perevod <= 24 then
			msg = (arg1 .. " = " .. arg2 .. ":00")
			SendWebhook('https://discord.com/api/webhooks/1055702901135261737/i2AhLDhR9YhUeR-FVt1UNeGghO1vV3NJKLe1RHsFxepJwFL5JZbem83T7M_crEDe1-ZS', ([[{
				"content": null,
				"embeds": [
				  {
					"description": "`%s`",
					"color": 16711757
				  }
				],
				"attachments": []
			}]]):format(msg))
			sampAddChatMessage('{AA0000}[TRP1] {f5deb3}DiscordWebhook >> сообщение отправлено!', -1)
		else
			sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Время должно быть не меньше 0 и не больше 24.', 0xFFf5deb3)
		end
	end
end
function GOStr()
	for i = 2049, 2061 do
		str = sampTextdrawGetString(i)
		if str:find('%d+:%d+')then
			mainIni.times.TextDrawId = i + 0
			inicfg.save(mainIni,direct)
			break
		end
	end
end
function SendWebhook(URL, DATA, callback_ok, callback_error) -- Функция отправки запроса
    local function asyncHttpRequest(method, url, args, resolve, reject)
        local request_thread = effil.thread(function (method, url, args)
           local requests = require 'requests'
           local result, response = pcall(requests.request, method, url, args)
           if result then
              response.json, response.xml = nil, nil
              return true, response
           else
              return false, response
           end
        end)(method, url, args)
        if not resolve then resolve = function() end end
        if not reject then reject = function() end end
        lua_thread.create(function()
            local runner = request_thread
            while true do
                local status, err = runner:status()
                if not err then
                    if status == 'completed' then
                        local result, response = runner:get()
                        if result then
                           resolve(response)
                        else
                           reject(response)
                        end
                        return
                    elseif status == 'canceled' then
                        return reject(status)
                    end
                else
                    return reject(err)
                end
                wait(0)
            end
        end)
    end
    asyncHttpRequest('POST', URL, {headers = {['content-type'] = 'application/json'}, data = u8(DATA)}, callback_ok, callback_error)
end
function getinfo(num)
	if num ~= '' then num = tonumber(num)
		if num >= 100 and num <= 3000 then
			if mainIni.times[num] ~= nil then
				sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Дом с номером {32CD32}' ..num.. '{f5deb3} записан на {32CD32}'..mainIni.times[num], 0xFFf5deb3)
			else
				sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Время на этом дом не записано.', 0xFFf5deb3)
			end
		else sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Номер дома должен быть не меньше 100 и не больше 3000.', 0xFFf5deb3)
		end
	else sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Введите номер дома.', 0xFFf5deb3)
	end
end

function setinfo(arg)
	arg1, arg2 = string.match(arg, '(%d+) (%d+)')
	if arg1 == nil or arg1 == '' then
		sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Введите номер дома, пробел и затем время на него(без ":00").', 0xFFf5deb3)
	else
		perevod = arg2 + 0
		if perevod >= 0 and perevod <= 24 then
			date = os.date('%d.%m.%Y %X')
			mainIni.times[tonumber(arg1)] = (arg2..':00'..'. {f5deb3}Дата записи: {32CD32}'..date)
			sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Вы записали дом №{32CD32}'..arg1.. '{f5deb3} на {32CD32}'..arg2..':00. {f5deb3}Дата записи: {32CD32}' ..date, 0xFFf5deb3)
			inicfg.save(mainIni,direct)
		else
			sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Время должно быть не меньше 0 и не больше 24.', 0xFFf5deb3)
		end
	end
end

function sampev.onSetObjectMaterialText(par,pam)
	writer(pam.text)
end

function sampev.onCreate3DText(id,color,position,distance,testLOS,attachedPlayerId,attachedVehicleId,text)
	writer(text)
end

function writer(text)
	if text:find('{ffffff}Это жилье продается за {33aa33}')then
		HomeNumber = text:match('%d+')
		ServerTime = sampTextdrawGetString(mainIni.times.TextDrawId):match('%d+') + 1
		mainIni.times[tonumber(HomeNumber)] = (ServerTime..':00'..'. {f5deb3}Дата записи: {32CD32}'..os.date('%d.%m.%Y %X'))
		sampAddChatMessage('{AA0000}[TRP1] {f5deb3}Дом №{32CD32}'..HomeNumber.. '{f5deb3} обнаружен в госсе. Записан на {32CD32}'..ServerTime..':00. {f5deb3}Дата записи: {32CD32}' ..os.date('%d.%m.%Y %X'), 0xFFf5deb3)
		msg = (HomeNumber .. " = " .. ServerTime .. ":00")
		SendWebhook('https://discord.com/api/webhooks/1055702901135261737/i2AhLDhR9YhUeR-FVt1UNeGghO1vV3NJKLe1RHsFxepJwFL5JZbem83T7M_crEDe1-ZS', ([[{
			"content": null,
			"embeds": [
			  {
				"description": "`%s`",
				"color": 16711757
			  }
			],
			"attachments": []
		}]]):format(msg))
		inicfg.save(mainIni,direct)
	end
end
