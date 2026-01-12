local ReplicatedStorage = game:GetService("ReplicatedStorage")

local g = require(ReplicatedStorage.Packages.GreenTea)

local punishmentSchema = g.table({
	reason = g.string(),
	privateReason = g.optional(g.string()),
	issuedBy = g.optional(g.number()),
	issuedAt = g.number(),
	duration = g.optional(g.number()),
	type = g.union(g.literal("ban"), g.literal("kick"), g.literal("warn"), g.literal("serverban")),
	isApiBan = g.optional(g.boolean()),
})

local profileSchema = g.build(g.table({
	Cash = g.number(),
	Items = g.optional(g.array(g.table({
		id = g.string(),
		ammo = g.optional(g.number()),
	}))),
	Punishments = g.array(punishmentSchema),
}))
local profileTemplate: typeof(profileSchema:type()) = {
	Cash = 100,
	Items = {},
	Punishments = {},
}

export type Profile = typeof(profileSchema:type())
export type Punishment = typeof(g.build(punishmentSchema):type())

return {
	profileTemplate = profileTemplate,
	profileSchema = profileSchema,
	punishmentSchema = g.build(punishmentSchema),
}
