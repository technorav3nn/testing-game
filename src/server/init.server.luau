local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require("@self/Services/DataService")
local Loader = require(ReplicatedStorage.Packages.Loader)

Loader.SpawnAll(Loader.LoadChildren(ServerScriptService.Server.Managers), "OnStart")
Loader.SpawnAll(Loader.LoadDescendants(ServerScriptService.Server.Managers.Network), "OnStart")

DataService:Init()

-- DataService.NewPlayerDataLoaded:Connect(function(player)
-- 	while true do
-- 		local hrp = (player.Character :: Model).PrimaryPart :: BasePart
-- 		local cashDrop = CashDrop.new(200, hrp.CFrame, false)
-- 		task.wait(1)
-- 	end
-- end)
