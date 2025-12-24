local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunServer = require(ReplicatedStorage.Modules.Gun.GunServer)

local gunHandler

script.Parent.Equipped:Connect(function()
	local char = (script.Parent :: Tool).Parent :: Model
	(char:WaitForChild("Humanoid") :: Humanoid).Died:Once(function()
		if gunHandler then
			gunHandler:Destroy()
			gunHandler = nil :: any
		end
	end)
	gunHandler = GunServer.new(script.Parent :: Tool)
end)

script.Parent.Unequipped:Connect(function()
	if gunHandler then
		gunHandler:Destroy()
		gunHandler = nil :: any
	end
end)
