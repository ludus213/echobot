local Types = {}

export type CharacterR6 = Model & {
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
	Head: BasePart,
	Torso: BasePart,
	LeftArm: BasePart,
	RightArm: BasePart,
	LeftLeg: BasePart,
	RightLeg: BasePart,
	Animator: Animator?,
}

return Types