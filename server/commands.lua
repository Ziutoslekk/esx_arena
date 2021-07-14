RegisterCommand("arena_host", function(source, args)
	if not Players[source] then
		local game = HostGame(tonumber(args[1]))

		if game then
			game.addPlayer(source)
		else
			TriggerClientEvent("esx:showNotification", source, "Wystąpił błąd podczas hostowania sesji, prawodopodobnie wszystkie dostępne sesje są zajęte.")
		end
	else
		TriggerClientEvent("esx:showNotification", source, "Jesteś już w trybie areny!")
	end
end, false)

RegisterCommand("arena_exit", function(source)
	ExitArena(source, true)
end, false)

