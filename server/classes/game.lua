New_Game = function(gameId, bucket, arenaId, rounds)
	local self = {}

	self.id = gameId
	self.bucket = bucket
	self.started = false
	self.roundActive = false

	self.settings = {}
	self.settings.arena = arenaId
	self.settings.rounds = rounds or 10
	self.settings.weapons = { "weapon_pistol" }

	self.round = 0
	self.teams = {}
	self.players = {}

	--[[ Common ]]--
	self.isHost = function(playerId)
		if self.getPlayer(playerId) then
			return self.players[playerId].host
		end

		return false
	end
	self.isStarted = function()
		return self.started
	end

	--[[ Sync ]]--
	self.syncAll = function(eventName, eventData)
		for id, player in pairs(self.getPlayers()) do
			TriggerClientEvent(("arenas:cl:" .. eventName), id, eventData)
		end
	end
	self.sync = function(playerId, eventName, eventData)
		if self.getPlayer(playerId) then
			TriggerClientEvent(("arenas:cl:" .. eventName), playerId, eventData)
		end
	end

	--[[ Arenas ]]--
	self.getArena = function()
		return self.settings.arena
	end
	self.setArena = function(arenaId)
		self.settings.arena = arenaId

		self.syncAll("update", { 
			arena = self.getArena()
		})
	end

	--[[ Rounds ]]--
	self.getRound = function()
		return self.round
	end
	self.getRounds = function()
		return self.settings.rounds
	end
	self.setRound = function(round)
		self.round = round

		self.syncAll("round", self.getRound())
	end
	self.setRounds = function(rounds)
		self.settings.rounds = rounds

		self.syncAll("update", { 
			rounds = self.getRounds()
		})

		return true
	end

	--[[ Weapons ]]--
	self.getWeapon = function(weapon)
		for index,weaponName in ipairs(self.settings.weapons) do
			if weaponName == weapon then
				return index
			end
		end

		return nil
	end
	self.getWeapons = function()
		return self.settings.weapons
	end
	self.addWeapon = function(weapon)
		if not self.getWeapon(weapon) then
			table.insert(self.settings.weapons, weapon)

			self.syncAll("update", { 
				weapons = self.getWeapons()
			})
		end
	end
	self.removeWeapon = function(weapon)
		local index = self.getWeapon(weapon)

		if index then
			table.remove(self.settings.weapons, index)

			self.syncAll("update", { 
				weapons = self.getWeapons()
			})
		end
	end

	--[[ Teams ]]--
	self.getTeam = function(teamId)
		return self.teams[teamId]
	end
	self.getTeams = function()
		return self.teams
	end
	self.addTeam = function()
		table.insert(self.teams, {
			dead = false,

			stats = {
				rounds = 0,

				kills = 0,
				deaths = 0
			}
		})
	end
	self.getTeamData = function(teamId, key)
		if self.getTeam(teamId) then		
			return self.teams[teamId][key]
		end

		return false
	end
	self.setTeamData = function(teamId, key, value)
		if self.getTeam(teamId) then		
			self.teams[teamId][key] = value
			
			return true
		end

		return false
	end

	--[[ Teams stats ]]--
	self.getTeamStat = function(teamId, stat)
		if self.getTeam(teamId) then
			return self.teams[teamId].stats[stat]
		end
	end
	self.getTeamStats = function(teamId)
		if self.getTeam(teamId) then
			return self.teams[teamId].stats
		end
	end
	self.addTeamStat = function(teamId, stat, value)
		if self.getTeam(teamId) then
			self.teams[teamId].stats[stat] = self.teams[teamId].stats[stat]+value
		end
	end
	self.setTeamStat = function(teamId, stat, value)
		if self.getTeam(teamId) then
			self.teams[teamId].stats[stat] = value
		end
	end

	--[[ Players ]]--	
	self.getPlayer = function(playerId)
		return self.players[playerId]
	end
	self.getPlayers = function(teamId, index)
		if teamId then
			local players = {}

			for id, player in pairs(self.players) do
				if player then
					if player.team == teamId then
						if index then
							table.insert(players, player)
						else
							players[id] = player
						end
					end
				end
			end

			return players
		else
			return self.players
		end
	end
	self.getPlayersCount = function(teamId)
		local players = 0

		for id, player in pairs(self.players) do
			if teamId then
				if player.team == teamId then
					players = players+1
				end
			else
				players = players+1
			end
		end

		return players
	end	
	self.getPlayersClient = function()
		local players = {}

		for id, player in pairs(self.players) do
			table.insert(players, {
				source = player.source,
				team = player.team
			})	
		end

		return players
	end
	self.addPlayer = function(playerId, teamId)
		if not self.started then
			if not self.getPlayer(playerId) then
				Players[playerId] = self.id

				self.players[playerId] = {}

				self.players[playerId].source = playerId
				self.players[playerId].team = teamId or math.random(1, #self.teams)

				self.players[playerId].ready = false
				self.players[playerId].dead = false

				self.players[playerId].stats = {
					kills = 0,
					deaths = 0
				}
	
				if self.getPlayersCount() == 1 then
					self.players[playerId].host = true
				end
				
				self.sync(playerId, "start", { 
					host = self.players[playerId].host,

					teams = #self.teams,
					team = self.players[playerId].team,

					round = self.getRound(),

					started = false,

					settings = self.settings
				})

				self.syncAll("players", self.getPlayersClient())

				print(("arenas: %s joined arena %s."):format(GetPlayerName(playerId), self.id))

				return true
			end
		end

		return false
	end	
	self.setPlayerTeam = function(playerId, teamId)
		if self.getPlayer(playerId) then
			if self.getTeam(teamId)	then
				self.players[playerId].team = teamId
				
				self.sync(playerId, "team", { 
					team = self.players[playerId].team,
				})

				self.syncAll("player", {
					playerId = playerId,

					update = {
						team = self.players[playerId].team
					}
				})
				
				return true
			end
		end

		return false
	end
	self.removePlayer = function(playerId, bypassCleanUp)
		if self.getPlayer(playerId) then	
			local isHost = self.players[playerId].host
			
			self.sync(playerId, "stop", bypassCleanUp)
			if GetPlayerRoutingBucket(playerId) ~= 0 then
				SetPlayerRoutingBucket(playerId, 0)
			end

			self.players[playerId] = nil
			Players[playerId] = nil

			self.syncAll("players", self.getPlayersClient())		

			if self.isStarted() then
				for teamId in ipairs(self.getTeams()) do
					if #self.getPlayers(teamId, true) == 0 then
						self.syncAll("feed", {
							type = "esx:showNotification",
							msg = "Jedna z drużyn opuściła arenę, trwa wybieranie zwycięzcy."
						})

						Citizen.SetTimeout(2000, function()
							StopGame(self.id, true)
						end)

						break
					end
				end
			else
				if isHost then
					Citizen.SetTimeout(0, function()
						self.syncAll("feed", {
							type = "esx:showNotification",
							msg = "Host opuścił lobby, trwa zamykanie sesji..."
						})
	
						Citizen.Wait(2000)
	
						StopGame(self.id)
					end)				
				end
			end

			return true
		end

		return false
	end

	--[[ Player data ]]--
	self.getPlayerData = function(playerId, key)
		if self.getPlayer(playerId) then		
			return self.players[playerId][key]
		end

		return false
	end
	self.setPlayerData = function(playerId, key, value)
		if self.getPlayer(playerId) then		
			self.players[playerId][key] = value
			
			return true
		end

		return false
	end

	--[[ Player stats ]]--
	self.addPlayerStat = function(playerId, stat, value, addTeam)
		if self.getPlayer(playerId) then		
			self.players[playerId].stats[stat] = self.players[playerId].stats[stat]+value

			if addTeam then
				self.addTeamStat(self.players[playerId].team, stat, value)
			end

			return true
		end

		return false
	end
	self.setPlayerStat = function(playerId, stat, value, setTeam)
		if self.getPlayer(playerId) then		
			self.players[playerId].stats[stat] = value
			
			if setTeam then
				self.setTeamStat(self.players[playerId].team, stat, value)
			end

			return true
		end

		return false
	end

	--[[ Main ]]--
	self.start = function()
		for teamId in ipairs(self.getTeams()) do
			if #self.getPlayers(teamId, true) == 0 then
				return false
			end
		end

		self.started = true
		self.startRound()
		
		return true
	end
	self.startRound = function()
		Citizen.SetTimeout(0, function()
			if not self.roundActive then
				local teamStats = {}

				for id in pairs(self.getTeams()) do
					self.setTeamData(id, "dead", false)

					teamStats[id] = self.getTeamStats(id)
				end

				for id, player in pairs(self.getPlayers()) do
					if GetPlayerRoutingBucket(id) ~= self.bucket then
						SetPlayerRoutingBucket(id, self.bucket)
					end
	
					self.setPlayerData(id, "ready", false)
					self.setPlayerData(id, "dead", false)	
	
					self.sync(id, "respawn", player.team)
					self.sync(id, "stats", teamStats)
				end
	
				local hasPlayersLoaded = true
				while true do
					Citizen.Wait(2500)

					hasPlayersLoaded = true
					for id in pairs(self.getPlayers()) do
						if not tonumber(self.getPlayerData(id, "ready")) then
							hasPlayersLoaded = false
							break
						end
					end
	
					if hasPlayersLoaded then						
						break
					end
				end
	
				self.setRound(self.getRound()+1)
				if self.getRound() > self.getRounds() then
					StopGame(self.id, true)
				else
					self.roundActive = true
					self.syncAll("unlock", self.getWeapons())

					self.afkTime = os.time()
					while self.roundActive do
						if not GetGame(self.id) then
							break
						end		
						
						if os.time()-self.afkTime >= Config.RoundTimeout then
							self.syncAll("feed", {
								type = "esx:showNotification",
								msg = "Sesja wygasła po upłynięciu limitu czasowego."
							})

							StopGame(self.id)

							break
						end

						Citizen.Wait(30000)
					end	
				end
			end
		end)		
	end

	--[[ Handlers ]]--
	self.onPlayerDeath = function(playerId, data)
		if self.started and self.roundActive then
			local player = self.getPlayer(playerId)
			self.setPlayerData(player.source, "dead", true)

			--// Add stats
			self.addPlayerStat(player.source, "deaths", 1, true)
			if data.killedByPlayer then
				if self.getPlayer(data.killerServerId) then
					self.addPlayerStat(data.killerServerId, "kills", 1, true)
					self.sync(data.killerServerId, "feed", { type = "effect_kill" })

					self.syncAll("feed", { 
						type = "chat_kill",

						killer_team = self.getPlayer(data.killerServerId).team,
						killer = data.killerServerId,
						
						victim_team = player.team,
						victim = playerId						
					})
				end
			end

			--// Process teams
			local isTeamDead = true
			for id in pairs(self.getPlayers(player.team)) do
				if not self.getPlayerData(id, "dead") then
					isTeamDead = false
					break
				end
			end

			if isTeamDead then
				self.setTeamData(player.team, "dead", true)

				local lastTeam = nil
				for id in pairs(self.getTeams()) do
					if not self.getTeamData(id, "dead") then
						if not lastTeam then
							lastTeam = id
						else
							lastTeam = nil
							break
						end
					end
				end

				if lastTeam then
					self.addTeamStat(lastTeam, "rounds", 1)
					self.roundActive = false

					Citizen.Wait(5000)

					self.startRound()
				end
			end
		end
	end
	self.onReady = function(playerId)
		if self.started and not self.roundActive then
			self.setPlayerData(playerId, "ready", 1)			
		end
	end


	--[[ Warmup ]]--
	self.hostTimeout = function()
		self.hostTime = os.time()

		Citizen.SetTimeout(0, function()
			while not self.isStarted() do
				if not GetGame(self.id) then
					break
				end

				if os.time()-self.hostTime >= Config.HostTimeout then
					self.syncAll("feed", {
						type = "esx:showNotification",
						msg = "Sesja wygasła po upłynięciu limitu czasowego."
					})
	
					StopGame(self.id)
	
					break
				end

				Citizen.Wait(5000)
			end
		end)
	end

	return self
end