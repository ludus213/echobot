local Shared = {}

Shared.DEFAULT_PLAYER_DATA = {
	LatentEcho = nil,
	echoType = "",
	origin = "",
	name = "",
	vestige = 5,
	enteredZones = {},
	skinTone = nil,
	skinToneIndex = 1,
	hairColor = nil,
	position = { x = -95.311, y = 9.88, z = -42.87 },
	Armor = nil,
	Weapon = "Echo Iron Sword",
	Relics = {},
	Skills = {},
	health = 100,
	SlotData = "{}",
	Inn = nil,
	MinutesSurvived = 0,
	DaysSurvived = 0,
	Stomach = 100
}

export type PlayerData = typeof(Shared.DEFAULT_PLAYER_DATA)

return Shared
