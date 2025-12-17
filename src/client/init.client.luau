local ReplicatedStorage = game:GetService("ReplicatedStorage")
local App = require(ReplicatedStorage.UI.App)
local vide = require(ReplicatedStorage.Packages.Vide)

print("Starting app...")

vide.mount(App, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
