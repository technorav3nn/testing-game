if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WalletView = require(ReplicatedStorage.UI.Views.Wallet)
local vide = require(ReplicatedStorage.Packages.Vide)

local tool = script.Parent :: Tool

local unmount
local mounted = false

local function cleanup()
	unmount();
	(Players.LocalPlayer.PlayerGui :: any).WalletView:Destroy()
end

tool.Activated:Connect(function()
	mounted = not mounted
	if mounted then
		unmount = vide.mount(WalletView, Players.LocalPlayer.PlayerGui)
	else
		cleanup()
	end
	task.wait()
end)

tool.Unequipped:Connect(function()
	if mounted then
		cleanup()
		mounted = not mounted
	end
end)
