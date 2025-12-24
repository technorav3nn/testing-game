local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)
local gt = require(ReplicatedStorage.Packages.GreenTea)

local schema = gt.build(gt.number({ integer = true, range = { min = 1, max = 10_000 } }))
local schemaRet = gt.build(gt.union(gt.number(), gt.bool()))

export type ReturnType = typeof(schemaRet:type())

return Red.Function("WalletDropCash", function(amount)
	local result = schema:assert(amount)
	return result
end, function(cooldown)
	local result = schemaRet:assert(cooldown)
	return result
end)
