ESX = nil
Arena = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Config.Weapons = ESX.GetWeaponsConfig()

	local scaleformHandle = RequestScaleformMovie_2("MP_MISSION_NAME_FREEMODE")
	while not HasScaleformMovieLoaded(scaleformHandle) do
		Citizen.Wait(0)
	end

	BeginScaleformMovieMethod(scaleformHandle, "SET_MISSION_INFO")
	PushScaleformMovieMethodParameterString('Wybierz arene!')
	PushScaleformMovieMethodParameterString("~b~ostatnia drużyna wygrywa~s~")
	PushScaleformMovieMethodParameterString("")
	PushScaleformMovieMethodParameterString("")
	PushScaleformMovieMethodParameterString("")
	EndScaleformMovieMethod()

	local playerCoords, vdist = nil, nil
	while true do
		if not Arena then
			playerCoords = GetEntityCoords(PlayerPedId())
			vdist = Vdist(playerCoords, Config.Hostpoint.x, Config.Hostpoint.y, Config.Hostpoint.z)

			if vdist < Config.ScaleformDistance then
				if vdist < 2.5 then
					ESX.ShowHelpNotification("Naciśnij ~INPUT_CONTEXT~ aby, wybrać arenę.")

					if IsControlJustPressed(0, 51) then
						OpenMainMenu()
					end
				end

				DrawScaleformMovie_3dSolid(scaleformHandle, Config.Hostpoint.x, Config.Hostpoint.y, Config.Hostpoint.z, 0.0, 0.0, GetScaleformRot(Config.Hostpoint, GetFinalRenderedCamCoord()), 1.0, 0.5, 0.5, 3.0, 3.0, 0.0, 2)			
				DrawMarker(1, Config.Hostpoint.x, Config.Hostpoint.y, Config.Hostpoint.z-1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 0.5, 66, 135, 245, 80, false, false, 0, false, nil, nil, false)					
			else
				Citizen.Wait(500)
			end
		else 
			Citizen.Wait(500)
		end

		Citizen.Wait(0)
	end
end)

GetScaleformRot = function(coords, coords_2)
	return (180.0 - GetHeadingFromVector_2d((coords_2.x - coords.x), (coords_2.y - coords.y)))
end


RegisterNetEvent("arenas:cl:start")
AddEventHandler("arenas:cl:start", function(gameData)
	if not Arena then
		Arena = gameData

		TriggerEvent("areanas:isInArena", true)

		BusySpinnerDisplay("Dołączanie do sesji")

		if Arena.host then
			ESX.ShowNotification("Jesteś hostem areny, pod przyciskiem F6 znajdziesz panel do zarządzania nią.")

			OpenMenu()
		else
			ESX.ShowNotification("Menu areny dostępne pod przyciskiem F6")
		end
	
		BusySpinnerDisplay("Oczekiwanie na rozpoczęcie sesji przez hosta")

		Citizen.SetTimeout(0, function()
			while IsArenaActive() do
				if Arena.started then
					if not IsPlayerDead(PlayerId()) then
						if IsScreenFadedIn() then
							if not IsInSafezone(GetArenaProperty("safezone")) then
								SetEntityHealth(PlayerPedId(), 0)
							end
						end
					end
				end
	
				Citizen.Wait(1000)
			end
		end)

		while IsArenaActive() do
			if IsControlJustPressed(0, 167) then
				OpenMenu()
			end

			if Arena.started then
				Draw2DText(("Wynik: %s"):format(GetScoreStr()), 0.5, 0.92, 0.6, 0.6, nil, nil, nil, nil, nil, 2)
				Draw2DText(("Runda: %s/%s"):format(Arena.round, Arena.settings.rounds), 0.5, 0.95, 0.75, 0.75, nil, nil, nil, nil, nil, 2)				
			end

			if Config.Debug then
				DrawMarker(28, GetArenaProperty("safezone").x, GetArenaProperty("safezone").y, GetArenaProperty("safezone").z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetArenaProperty("safezone").w, GetArenaProperty("safezone").w, GetArenaProperty("safezone").w, 0, 255, 0, 120, false, false, 0, false, nil, nil, false)
			end

			Citizen.Wait(10)
		end
	end
end)

RegisterNetEvent("arenas:cl:unlock")
AddEventHandler("arenas:cl:unlock", function(weapons)
	if Arena then
		FreezeEntityPosition(PlayerPedId(), false)

		RemoveAllPedWeapons(PlayerPedId())
		for index,weapon in ipairs(weapons) do
			GiveWeaponToPed(PlayerPedId(), GetHashKey(weapon), 500, false, true)
		end

		if BusyspinnerIsDisplaying() then
			BusyspinnerOff()
		end

		if not IsScreenFadedIn() and not IsScreenFadingIn() then
			DoScreenFadeIn(1000)

			while not IsScreenFadedIn() do
				Citizen.Wait(0)
			end
		end

		local scaleformHandle = RequestScaleformMovie_2("COUNTDOWN")
		while not HasScaleformMovieLoaded(scaleformHandle) do
			Citizen.Wait(0)
		end

		local drawScaleform = true
		Citizen.SetTimeout(0, function()
			BeginScaleformMovieMethod(scaleformHandle, "SET_COUNTDOWN_LIGHTS")
			ScaleformMovieMethodAddParamInt(10)
			EndScaleformMovieMethod()

			while drawScaleform do			
				DrawScaleformMovieFullscreen(scaleformHandle, 255, 255, 255, 255)
				Citizen.Wait(0)
			end
		end)	

		for i=3, 0, -1 do
			SetCountdownScaleform(scaleformHandle, ((i == 0 and "GO") or tostring(i)))
			PlaySoundFrontend(-1, "Countdown_" .. i, "DLC_AW_Frontend_Sounds", 1)

			if i == 1 then
				Citizen.SetTimeout(250, function()
					PlaySoundFrontend(-1, "Countdown_GO", "DLC_AW_Frontend_Sounds", 1)
				end)	
			end

			Citizen.Wait(1000)
		end

		SetPlayerControl(PlayerId(), true, 0)

		Citizen.Wait(1000)
		drawScaleform = false		
	end
end)

RegisterNetEvent("arenas:cl:respawn")
AddEventHandler("arenas:cl:respawn", function(teamId)
	if Arena then
		if not Arena.started then
			Arena.started = true
		end

		FreezeEntityPosition(PlayerPedId(), true)

		if not IsScreenFadedOut() and not IsScreenFadingOut() then
			DoScreenFadeOut(300)

			while not IsScreenFadedOut() do
				Citizen.Wait(0)
			end
		end

		BusySpinnerDisplay("Oczekiwanie na połączenie wszystkich graczy")

		local spawnPoint = false
		for _,pos in ipairs(GetArenaProperty("spawnpoints")[teamId]) do
			if ESX.Game.IsSpawnPointClear(vector3(pos.x, pos.y, pos.z), 1.0) then
				spawnPoint = true

				RequestCollisionAtCoord(pos.x, pos.y, pos.z)
				StartPlayerTeleport(PlayerId(), pos, true, false, false)
				while not Citizen.InvokeNative(0xE23D5873C2394C61, PlayerId()) do
					Citizen.Wait(0)
				end

				NetworkResurrectLocalPlayer(pos, false, false)				
				ClearPedTasksImmediately(PlayerPedId())
				ClearPedBloodDamage(PlayerPedId())

				SetPlayerControl(PlayerId(), false, 256)			

				TriggerServerEvent("arenas:sv:ready")

				break
			end
		end

		if not spawnPoint then
			TriggerEvent("arenas:cl:respawn", teamId)
			print("Re-triggering respawn.")
		end
	end
end)

RegisterNetEvent("arenas:cl:player")
AddEventHandler("arenas:cl:player", function(data)
	if Arena then
		local player, index = GetPlayer(data.playerId)

		if player then
			for k,v in pairs(data.update) do
				Arena.players[index][k] = v
			end
		end
	end
end)

RegisterNetEvent("arenas:cl:players")
AddEventHandler("arenas:cl:players", function(players)
	if Arena then
		Arena.players = players
	end
end)

RegisterNetEvent("arenas:cl:round")
AddEventHandler("arenas:cl:round", function(round)
	if Arena then
		Arena.round = round
	end
end)

RegisterNetEvent("arenas:cl:stats")
AddEventHandler("arenas:cl:stats", function(stats)
	if Arena then
		Arena.stats = stats
	end
end)

RegisterNetEvent("arenas:cl:update")
AddEventHandler("arenas:cl:update", function(data)
	if Arena then
		if Arena.settings then
			for k,v in pairs(data) do
				Arena.settings[k] = v
			end
		end
	end
end)

RegisterNetEvent("arenas:cl:endflow")
AddEventHandler("arenas:cl:endflow", function(data)
	print("Endflow...")
end)

RegisterNetEvent("arenas:cl:feed")
AddEventHandler("arenas:cl:feed", function(data)
	if Arena then
		if (data.type == "chat_kill") then
			if IsAlly(data.killer_team) then
				data.killer = ("~%s~%s~s~"):format("b", GetPlayerName( GetPlayerFromServerId(data.killer) ))
			else
				data.killer = ("~%s~%s~s~"):format("r", GetPlayerName( GetPlayerFromServerId(data.killer) ))
			end

			if IsAlly(data.victim_team) then
				data.victim = ("~%s~%s~s~"):format("b", GetPlayerName( GetPlayerFromServerId(data.victim) ))
			else
				data.victim = ("~%s~%s~s~"):format("r", GetPlayerName( GetPlayerFromServerId(data.victim) ))
			end

			ESX.ShowNotification(("%s %s %s"):format(data.killer, Config.KillMessages[math.random(1, #Config.KillMessages)], data.victim))
		elseif (data.type == "esx:showNotification") then
			ESX.ShowNotification(data.msg)
		end
	end
end)

RegisterNetEvent("arenas:cl:stop")
AddEventHandler("arenas:cl:stop", function(bypassCleanUp)
	if Arena then
		local arenaId = Arena.settings.arena
		Arena = nil

		TriggerEvent("areanas:isInArena", false)

		if not bypassCleanUp then
			local hostpoint = Config.Arenas[arenaId].hostpoint

			RemoveAllPedWeapons(PlayerPedId())
			if not IsScreenFadedOut() and not IsScreenFadingOut() then
				DoScreenFadeOut(0)
			end

			BusySpinnerDisplay("Łączenie z główną sesją YOUR NAME")

			RequestCollisionAtCoord(hostpoint.x, hostpoint.y, hostpoint.z)
			StartPlayerTeleport(PlayerId(), hostpoint, true, true, true)
			while not Citizen.InvokeNative(0xE23D5873C2394C61, PlayerId()) do
				Citizen.Wait(0)
			end

			if BusyspinnerIsDisplaying() then
				BusyspinnerOff()
			end

			AnimpostfxStopAll()
			SetPlayerControl(PlayerId(), true, 0)
			
			if not IsScreenFadedIn() and not IsScreenFadingIn() then
				DoScreenFadeIn(5000)

				while not IsScreenFadedIn() do
					Citizen.Wait(0)
				end
			end
		end
	end
end)

RegisterNetEvent("arena:invite:showInvite")
AddEventHandler("arena:invite:showInvite", function(src, trg)
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'invite', {
		title    = ("Zaproszenie od %s"):format(GetPlayerName(GetPlayerFromServerId(src))),
		align    = 'right',
		elements = {
			{ label = "Przyjmij", value = 1 },
			{ label = "Odrzuć", value = 0 }
		}
	}, function(data, menu)
		if (data.current.value == 1) then
			TriggerServerEvent("arenas:sv:invite2", src, trg, true)

			menu.close()
		elseif (data.current.value == 0) then
			TriggerServerEvent("arenas:sv:invite2", src, trg, false)

			menu.close()
		end
	end, function(data, menu)
		TriggerServerEvent("arenas:sv:invite2", src, trg, false)

		menu.close()
	end)
end)

--[[ Arena ]]--
IsArenaActive = function()
	return Arena ~= nil
end

IsAlly = function(team)
	if Arena then
		return Arena.team == team
	end

	return false
end

OpenMainMenu = function()
	local elements = {}

	for id, arena in ipairs(Config.Arenas) do
		table.insert(elements, { label = arena.label, value = id })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'select_arena', {
		title    = "Areny",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent("arenas:sv:requestGame", data.current.value)

		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end

OpenMenu = function()
	local elements = {{ label = "Opuść arenę", value = "exit" }}

	if Arena.host then
		if not Arena.started then
			table.insert(elements, 1, { label = "Host", value = "host" })
		else
			ESX.ShowNotification("Panel hosta jest niedostępny w trakcie pojedynku!")
		end
	end

	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menu', {
		title    = "Arena",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		if (data.current.value == "host") then
			OpenHostMenu()
		elseif (data.current.value == "exit") then
			TriggerServerEvent("arenas:sv:exit")

			menu.close()
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenHostMenu = function()
	if not Arena.host then
		return
	end

	if Arena.started then
		return
	end

	ESX.UI.Menu.Close("default", GetCurrentResourceName(), 'host')
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'host', {
		title    = "Host",
		align    = 'right',
		elements = {
			{ label = ("Arena - %s"):format(Config.Arenas[Arena.settings.arena].label), value = "set_arena" },
			{ label = ("Rundy - %s"):format(Arena.settings.rounds), value = "set_rounds" },
			{ label = "Bronie", value = "weapons" },
			{ label = "Gracze", value = "players" },
			{ label = "Start", value = "start" }
		}
	}, function(data, menu)
		if (data.current.value == "set_arena") then
			OpenArenasMenu()

		elseif (data.current.value == "set_rounds") then
			OpenRoundsMenu()
		
		elseif (data.current.value == "weapons") then
			OpenWeaponsMenu()

		elseif (data.current.value == "players") then
			OpenPlayersMenu()

		elseif (data.current.value == "start") then
			TriggerServerEvent("arenas:sv:start")	
			ESX.UI.Menu.CloseAll()			
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenArenasMenu = function()
	local elements = {}

	for id, arena in ipairs(Config.Arenas) do
		table.insert(elements, { label = arena.label, value = id })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'arenas_select', {
		title    = "Areny",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent("arenas:sv:setArena", data.current.value)

		menu.close()
		Citizen.Wait(300)
		OpenHostMenu()
	end, function(data, menu)
		menu.close()
	end)
end

OpenRoundsMenu = function()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'round_select', {
		title = "Wybierz liczbę rund"
	}, function(data, menu)
		local amount = tonumber(data.value)

		if amount and amount > 0 and ((max and amount <= max) or not max) then
			TriggerServerEvent("arenas:sv:setRounds", amount)	

			menu.close()
			Citizen.Wait(300)
			OpenHostMenu()			
		else
			ESX.ShowNotification("Nieprawidłowa wartość.")
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenWeaponsMenu = function()
	local elements = {}

	for _,weapon in ipairs(Config.Weapons) do
		weapon.name = weapon.name:lower()

		if IsWeaponAllowed(weapon.name) then
			table.insert(elements, { label = weapon.label, value = weapon.name })
		else
			table.insert(elements, { label = ('<span style="color: %s;">%s</span>'):format("#525252", weapon.label), value = weapon.name })		
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weapons', {
		title    = "Bronie",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent("arenas:sv:setWeapon", data.current.value, (not IsWeaponAllowed(data.current.value)))

		menu.close()
		Citizen.Wait(300)
		OpenWeaponsMenu()
	end, function(data, menu)
		menu.close()
	end)
end

OpenPlayersMenu = function()
	local elements = {}

	table.insert(elements, { label = "Zaproś gracza", value = "invite" })

	for _,player in ipairs(Arena.players) do
		table.insert(elements, { label = GetPlayerName(GetPlayerFromServerId(player.source)), value = player.source })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'players_menu', {
		title    = "Gracze",
		align    = 'right',
		elements = elements
	}, function(data, menu)		
		if (data.current.value == "invite") then
			OpenInviteMenu()
		else
			OpenPlayerMenu(data.current.value)
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenPlayerMenu = function(playerId)
	local player = GetPlayer(playerId)

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_menu', {
		title    = GetPlayerName(GetPlayerFromServerId(player.source)),
		align    = 'right',
		elements = {
			{ label = "Drużyna: " .. player.team, value = nil },
			{ label = "Zmień drużynę", value = "change_team" },
			{ label = "Wyrzuć", value = "kick" }
		}
	}, function(data, menu)		
		if (data.current.value == "change_team") then
			local elements2 = {}
	
			for i=1, Arena.teams do 
				table.insert(elements2, { label = ("Drużyna #%s [%s] %s"):format(i, #GetPlayers(i), (Arena.team == i and " (TWOJA)") or ""), value = i })
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_set_team', {
				title    = "Wybierz drużynę",
				align    = 'right',
				elements = elements2
			}, function(data2, menu2)
				TriggerServerEvent("arenas:sv:team", player.source, data2.current.value)

				menu2.close()
				menu.close()
				Citizen.Wait(300)
				OpenPlayerMenu(playerId)
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif (data.current.value == "kick") then
			TriggerServerEvent("arenas:sv:kick", player.source)

			menu.close()
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenInviteMenu = function()
	local elements = {}

	for _,player in ipairs(ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 8.0)) do
		table.insert(elements, { label = GetPlayerName(player), value = GetPlayerServerId(player) })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_invite', {
		title    = "Zaproś gracza",
		align    = 'right',
		elements = elements
	}, function(data, menu)		
		local elements2 = {}
	
		for i=1, Arena.teams do 
			table.insert(elements2, { label = ("Drużyna %s / %s %s"):format(i, #GetPlayers(i), (Arena.team == i and "/ (TWOJA)") or ""), value = i })
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_invite_team_select', {
			title    = "Wybierz drużynę",
			align    = 'right',
			elements = elements2
		}, function(data2, menu2)
			TriggerServerEvent("arenas:sv:invite", data.current.value, data2.current.value)

			ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'players_menu')
			menu2.close()
			menu.close()
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		menu.close()
	end)
end


--[[ Utils ]]--
SetCountdownScaleform = function(scaleformHandle, msg)
	BeginScaleformMovieMethod(scaleformHandle, "SET_MESSAGE")
	PushScaleformMovieMethodParameterString(msg)
	ScaleformMovieMethodAddParamInt(math.ceil( Config.Colors[msg].x ))
	ScaleformMovieMethodAddParamInt(math.ceil( Config.Colors[msg].y ))
	ScaleformMovieMethodAddParamInt(math.ceil( Config.Colors[msg].z ))
	ScaleformMovieMethodAddParamBool(true)
	EndScaleformMovieMethod()
end

GetPlayer = function(playerId)
	for _,player in ipairs(Arena.players) do
		if player.source == playerId then
			return player, _
		end
	end

	return nil
end
GetPlayers = function(teamId)
	if teamId then
		local players = {}

		for _,player in ipairs(Arena.players) do
			if player.team == teamId then
				table.insert(players, player)
			end
		end

		return players
	else
		return Arena.players
	end
end

GetScoreStr = function()
	if not Arena then
		return nil
	end

	if not Arena.stats then
		return nil
	end

	local str = {}
	for teamId,teamStats in pairs(Arena.stats) do
		if IsAlly(teamId) then
			table.insert(str, 1, teamStats["rounds"] or 0)
		else
			table.insert(str, teamStats["rounds"] or 0)
		end
	end

	return table.concat(str, "/")
end

GetArenaProperty = function(property)
	return Config.Arenas[Arena.settings.arena][property]
end

IsInSafezone = function(safezone)
	return Vdist(GetEntityCoords(PlayerPedId()), safezone.x, safezone.y, safezone.z) <= safezone.w
end

IsWeaponAllowed = function(weaponName)
	for _,weapon in ipairs(Arena.settings.weapons) do
		if weapon == weaponName then
			return true
		end
	end

	return false
end

BusySpinnerDisplay = function(text)
	AddTextEntry("GTAO_BUSYSPINNER", "~a~")

	BeginTextCommandBusyspinnerOn("GTAO_BUSYSPINNER")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandBusyspinnerOn(4)
end

Draw2DText = function(text, x, y, scaleX, scaleY, font, r, g, b, a, align)
	SetTextFont(font or 1)
    SetTextCentre(true)
    SetTextWrap(0.0, 1.0)
    SetTextScale(scaleX, scaleY)
    SetTextEdge(1, 0, 0, 0, 205)
    SetTextColour(r or 102, g or 255, b or 102, a or 255)
    SetTextDropshadow(2, 2, 0, 0, 0)
            
	SetTextJustification(align or 0)

    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

--[[ Exports ]]--
IsInArena = function(andStarted)
	if andStarted then
		return Arena ~= nil and Arena.started == true
	end

	return Arena ~= nil
end

AddEventHandler("onResourceStop", function(rsc)
	if GetCurrentResourceName() == rsc then
		if Arena then
			if not IsScreenFadedIn() and not IsScreenFadingIn() then
				DoScreenFadeIn(300)
			end

			FreezeEntityPosition(PlayerPedId(), false)
			SetPlayerControl(PlayerId(), true, 0)

			if BusyspinnerIsDisplaying() then
				BusyspinnerOff()
			end
		end
	end	
end)