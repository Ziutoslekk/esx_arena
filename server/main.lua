Games = {}
Players = {}
Invites = {}
RoutingBuckets = {}

--[[ Game ]]--
GetGame = function(gameId)
	if Games[gameId] ~= 0 then
		return Games[gameId]
	end

	return nil
end
HostGame = function(arenaId, teamSize)
	if not arenaId then
		arenaId = math.random(1, #Config.Arenas)
	end

	if not Config.Arenas[arenaId] then
		return false
	end

	local routingBucket = GetFreeRoutingBucket()
	if routingBucket then
		local gameId = #Games+1

		if not GetGame(gameId) then
			Games[gameId] = New_Game(gameId, routingBucket, arenaId)
			
			for i=1, teamSize or 2 do
				Games[gameId].addTeam()
			end

			Games[gameId].hostTimeout()

			print(("arenas: Hosted new game with id %s!"):format(gameId))
			return Games[gameId]
		end
	end

	return false
end
StopGame = function(gameId, endflow)
	local game = GetGame(gameId)
	
	if game then
		if endflow then
			game.syncAll("endflow", {
				players = game.getPlayers(),
				teams = game.getTeams(),
				arena = game.getArena()
			})
		end

		for playerId in pairs(game.getPlayers()) do
			game.removePlayer(playerId)
		end

		SetRoutingBucketAsFree(Games[gameId].bucket)
		Games[gameId] = 0

		print(("arenas: Stopped game with id %s!"):format(gameId))
		return true
	end

	return false
end


--[[ Arenas ]]--
ExitArena = function(playerId, notification, kicked)
	if Players[playerId] then
		local game = GetGame(Players[playerId])

		if game then
			game.removePlayer(playerId)

			if notification then
				if kicked then
					game.syncAll("notification", ("%s został wyrzucony z areny."):format(GetPlayerName(playerId)))
				else
					game.syncAll("notification", ("%s opuścił arenę."):format(GetPlayerName(playerId)))
				end
			end
		end
	end
end

--[[ Routing buckets ]]--
GetFreeRoutingBucket = function()
	for i=1, Config.MaxSessions do
		if not RoutingBuckets[i] then
			RoutingBuckets[i] = true

			return i
		end
	end
end
SetRoutingBucketAsFree = function(routingBucket)
	if RoutingBuckets[routingBucket] then
		RoutingBuckets[routingBucket] = nil
	end
end

--[[ Events ]]--
RegisterServerEvent("arenas:sv:requestGame")
AddEventHandler("arenas:sv:requestGame", function(arenaId)
	if not Players[source] then
		local game = HostGame(tonumber(arenaId))

		if game then
			game.addPlayer(source)
		else
			TriggerClientEvent("esx:showNotification", source, "Wystąpił błąd podczas hostowania sesji, prawodopodobnie wszystkie dostępne sesje są zajęte.")
		end
	end
end)

RegisterServerEvent("arenas:sv:setArena")
AddEventHandler("arenas:sv:setArena", function(arenaId)
	if arenaId and Config.Arenas[arenaId] then
		if Players[source] then
			local game = GetGame(Players[source])

			if game and game.isHost(source) and not game.isStarted() then
				if game.getArena() ~= arenaId then
					game.setArena(arenaId)
				end
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:setRounds")
AddEventHandler("arenas:sv:setRounds", function(rounds)
	if rounds and rounds > 0 and rounds <= Config.MaxRounds then
		if Players[source] then
			local game = GetGame(Players[source])

			if game and game.isHost(source) and not game.isStarted() then
				if game.getRounds() ~= rounds then
					game.setRounds(rounds)
				end
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:setWeapon")
AddEventHandler("arenas:sv:setWeapon", function(weapon, allow)
	if Players[source] then
		local game = GetGame(Players[source])

		if game and game.isHost(source) and not game.isStarted() then
			if allow then
				game.addWeapon(weapon)
			else
				game.removeWeapon(weapon)
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:invite")
AddEventHandler("arenas:sv:invite", function(id, team)
	if Players[source] then
		if not Players[id] then
			if GetPlayerPing(id) > 0 then
				New_Invite(source, id, function(src, trg)
					local game = GetGame(Players[src])

					if game and game.isHost(src) and not game.isStarted() then
						if game.addPlayer(trg, team) then
							TriggerClientEvent("esx:showNotification", src, ("%s przyjął zaproszenie."):format(GetPlayerName(trg)))
						end
					else
						TriggerClientEvent("esx:showNotification", id, ("Wystąpił błąd podczas przetwarzania zaproszenia."):format(GetPlayerName(trg)))
					end
				end, function(src, trg, timeout)
					if timeout then
						TriggerClientEvent("esx:showNotification", src, ("%s przekroczył limit czasu na odpowiedź."):format(GetPlayerName(trg)))
					else
						TriggerClientEvent("esx:showNotification", src, ("%s odrzucił zaproszenie."):format(GetPlayerName(trg)))
					end
				end)
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:team")
AddEventHandler("arenas:sv:team", function(id, team)
	if Players[source] then
		if Players[id] then
			local game = GetGame(Players[source])

			if game and game.isHost(source) and not game.isStarted() then
				if game.getPlayer(id) then
					game.setPlayerTeam(id, team)
				end
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:kick")
AddEventHandler("arenas:sv:kick", function(id)
	if Players[source] then
		if Players[id] then
			local game = GetGame(Players[source])

			if game and game.isHost(source) and not game.isStarted() then
				if game.getPlayer(id) then
					if not game.isHost(id) then
						ExitArena(id, true, true)
					else
						TriggerClientEvent("esx:showNotification", source, "Nie możesz siebie wyrzucić?")
					end
				end
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:start")
AddEventHandler("arenas:sv:start", function()
	if Players[source] then
		local game = GetGame(Players[source])

		if game and game.isHost(source) and not game.isStarted() then
			if not game.start() then
				TriggerClientEvent("esx:showNotification", source, "Nie możesz uruchomić sesji gdy drużyny są puste.")
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:ready")
AddEventHandler("arenas:sv:ready", function()
	if Players[source] then
		local game = GetGame(Players[source])

		if game and game.isStarted() then
			if game["onReady"] then
				game["onReady"](source)
			end
		end
	end
end)

RegisterServerEvent("esx:onPlayerDeath")
AddEventHandler("esx:onPlayerDeath", function(data)
	if Players[source] then
		local game = GetGame(Players[source])

		if game and game.isStarted() then
			if game["onPlayerDeath"] then
				game["onPlayerDeath"](source, data)
			end
		end
	end
end)

RegisterServerEvent("arenas:sv:exit")
AddEventHandler("arenas:sv:exit", function()
	ExitArena(source, true)
end)

RegisterServerEvent("arenas:sv:invite2")
AddEventHandler("arenas:sv:invite2", function(src, trg, accepted)
	local invite = FindInvite(src, trg)

	if invite then
		if accepted then
			invite.accept()
		else
			invite.reject()
		end
	else
		TriggerClientEvent("esx:showNotification", source, "Wystąpił błąd podczas aktualizowania zaproszenia, zaproszenie mogło wygasnąć.")
	end
end)


AddEventHandler("onResourceStop", function(rsc)
	if GetCurrentResourceName() == rsc then
		for id in ipairs(Games) do
			if GetGame(id) then
				StopGame(id)
			end
		end
	end
end)

AddEventHandler("playerDropped", function()
	ExitArena(source, true)
end)

FindInvite = function(source, target)
	for index,invite in ipairs(Invites) do
		if (invite.src == source) and (invite.trg == target) then
			return invite, index
		end
	end

	return nil
end