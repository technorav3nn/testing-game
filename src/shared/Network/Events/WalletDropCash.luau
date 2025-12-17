local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)
local gt = require(ReplicatedStorage.Packages.GreenTea)

local schema = gt.build(gt.number({ integer = true, range = { min = 1, max = 10_000 } }))

return Red.Event("WalletDropCash", function(amount)
	local result = schema:assert(amount)
	print(result)
	return result
end)
