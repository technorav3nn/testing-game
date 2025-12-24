local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Conch = require(ReplicatedStorage.Packages.Conch)
local Loader = require(ReplicatedStorage.Packages.Loader)
local Sift = require(ReplicatedStorage.Packages.Sift)

local ConchServerManager = {}

local SUPER_USERS = { 883091636 }

function ConchServerManager.OnStart()
	Conch.initiate_default_lifecycle()

	Loader.SpawnAll(Loader.LoadChildren(script.Commands), "Register")

	local function playerAdded(player: Player)
		local user = Conch.get_user(player)

		if RunService:IsStudio() or Sift.Array.includes(SUPER_USERS, (user :: any).id) then
			Conch.give_roles(user, "super-user")
		end
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end
end

return ConchServerManager
