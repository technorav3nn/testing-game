local ReplicatedStorage = game:GetService("ReplicatedStorage")

local g = require(ReplicatedStorage.Packages.GreenTea)

local profileSchema = g.build(g.table({
	Cash = g.number(),
	Items = g.optional(g.array(g.table({
		Id = g.string(),
		Ammo = g.optional(g.number()),
	}))),
}))
local profileTemplate: typeof(profileSchema:type()) = {
	Cash = 100,
	Items = {},
}

export type Profile = typeof(profileSchema:type())

return {
	profileTemplate = profileTemplate,
	profileSchema = profileSchema,
}
