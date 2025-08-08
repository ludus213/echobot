local weaponInfo = {
	["Echo Iron Sword"] = {
		weaponType = "Sword",
		damage = 8,
		attackSpeed = 1.0,
		M1Amount = 5,
		chip = false,
		critDamage = 12,
		blockDamageReduction = 0.8,
		gripAnimation = game.ReplicatedStorage.Animations.StateAnimations["Sword Grip"]
	},
	["Resonant Silver Sword"] = {
		weaponType = "Sword",
		damage = 10,
		attackSpeed = 1.0,
		M1Amount = 5,
		chip = false,
		critDamage = 15,
		blockDamageReduction = 0.8,
		gripAnimation = game.ReplicatedStorage.Animations.StateAnimations["Sword Grip"]
	},
	["Aethersteel Sword"] = {
		weaponType = "Sword",
		damage = 14,
		attackSpeed = 1.15,
		M1Amount = 5,
		chip = true,
		critDamage = 21,
		blockDamageReduction = 0.7,
		gripAnimation = game.ReplicatedStorage.Animations.StateAnimations["Sword Grip"]
	},
	["Fist"] = {
		weaponType = "Fist",
		damage = 5,
		attackSpeed = 1.2,
		M1Amount = 5,
		chip = false,
		critDamage = 8,
		blockDamageReduction = 0.9,
		gripAnimation = game.ReplicatedStorage.Animations.StateAnimations["Sword Grip"]
	},
}

return weaponInfo
