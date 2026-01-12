local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require("@self/Services/DataService")
local Loader = require(ReplicatedStorage.Packages.Loader)

DataService:Init()

Loader.SpawnAll(Loader.LoadChildren(ServerScriptService.Server.Services), "OnStart")
Loader.SpawnAll(Loader.LoadChildren(ServerScriptService.Server.Services.World), "OnStart")
Loader.SpawnAll(Loader.LoadDescendants(ServerScriptService.Server.Services.NetworkService), "OnStart")

Loader.LoadDescendants(script.Components)

-- DataService.NewPlayerDataLoaded:Connect(function(player)
-- 	while true do
-- 		local hrp = (player.Character :: Model).PrimaryPart :: BasePart
-- 		local cashDrop = CashDrop.new(200, hrp.CFrame, false)
-- 		task.wait(1)
-- 	end
-- end)
