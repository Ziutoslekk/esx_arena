New_Invite = function(source, target, onAccept, onReject)
	local self = {}

	self.src = source
	self.trg = target

	--[[ Functions ]]--
	self.accept = function()
		self.delete()

		if onAccept and type(onAccept) == "function" then		
			onAccept(self.src, self.trg)
		end
	end
	self.reject = function(timeouted)
		self.delete()

		if onReject and type(onReject) == "function" then
			onReject(self.src, self.trg, timeouted)
		end
	end
	self.delete = function()
		local invite, index = FindInvite(self.src, self.trg)

		if invite then
			table.remove(Invites, index)
		end
	end

	--[[ Main ]]--
	table.insert(Invites, self)
	Citizen.SetTimeout(Config.InviteTimeout, function()
		local invite = FindInvite(self.src, self.trg)

		if invite then
			invite.reject(true)
		end
	end)

	TriggerClientEvent("esx:showNotification", self.src, ("Wysłano zaproszenie do %s!"):format(GetPlayerName(self.trg)))
	TriggerClientEvent("arena:invite:showInvite", self.trg, self.src, self.trg)
end