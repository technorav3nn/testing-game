local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Packages.Loader)
local vide = require(ReplicatedStorage.Packages.Vide)

local App = require(ReplicatedStorage.UI.App)

print("Starting app...")

Loader.SpawnAll(Loader.LoadChildren(script.Managers), "OnStart")
-- Loader.SpawnAll(Loader.LoadDescendants(script.Managers.Network), "OnStart")
vide.mount(App, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
