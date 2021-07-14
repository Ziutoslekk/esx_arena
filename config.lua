Config = {}

Config.Debug = false

Config.ScaleformDistance = 50.0

Config.MaxSessions = 63
Config.MaxRounds = 25

Config.InviteTimeout = 15000
Config.RoundTimeout = math.ceil(60 * 5)
Config.HostTimeout = math.ceil(60 * 2)

Config.Hostpoint = vector4(710.11, -984.36, 24.13, 8.0)

Config.Arenas = {
	{ 
		label = "Silos",
		hostpoint = vector4(710.11, -984.36, 24.13, 8.0),
		safezone = vector4(285.38, -2430.11, 12.84, 100.0),
		spawnpoints = {
			[1] = {
				vector4(284.77, -2446.88, 8.04, 350.0),
				vector4(284.77, -2446.88, 8.04, 350.0),
				vector4(284.77, -2446.88, 8.04, 350.0),
				vector4(284.77, -2446.88, 8.04, 350.0),
				vector4(284.77, -2446.88, 8.04, 350.0)
			},
			[2] = {
				vector4(290.15, -2414.66, 8.04, 172.0),
				vector4(290.15, -2414.66, 8.04, 172.0),
				vector4(290.15, -2414.66, 8.04, 172.0),
				vector4(290.15, -2414.66, 8.04, 172.0),
				vector4(290.15, -2414.66, 8.04, 172.0)
			}
		}
	},
	{
		label = "Elektrownia",
		hostpoint = vector4(710.11, -984.36, 24.13, 8.0),
		safezone = vector4(2719.63, 1355.92, 44.56, 100.0),
		spawnpoints = {
			[1] = { 
				vector4(2679.72, 1356.19, 24.92, 270.0),
				vector4(2679.72, 1356.19, 24.92, 270.0),
				vector4(2679.72, 1356.19, 24.92, 270.0),
				vector4(2679.72, 1356.19, 24.92, 270.0),
				vector4(2679.72, 1356.19, 24.92, 270.0)
			},
			[2] = {
				vector4(2757.63, 1356.63, 24.92, 90.0),
				vector4(2757.63, 1356.63, 24.92, 90.0),
				vector4(2757.63, 1356.63, 24.92, 90.0),
				vector4(2757.63, 1356.63, 24.92, 90.0),
				vector4(2757.63, 1356.63, 24.92, 90.0)
			}
		}
	}
}

Config.Weapons = {}

Config.KillMessages = {
	"zabija",
	"dziurawi"
}

Config.Colors = {
	["3"] = vector3(0, 171, 11),
	["2"] = vector3(171, 105, 0),
	["1"] = vector3(117, 0, 0),
	["GO"] = vector3(3, 66, 161)
}