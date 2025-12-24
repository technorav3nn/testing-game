local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Lucide = require(ReplicatedStorage.Packages.LucideIcons)
local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)
local create = vide.create

local function LoadingSpinner()
	local label = Lucide.ImageLabel("loader-circle", 32, {
		Size = UDim2.fromScale(0.9, 0.9),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageColor3 = theme.colors.neutral,
	})
	TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		Rotation = 360,
	}):Play()
	return create "Frame" {
		Size = UDim2.fromScale(0.5, 1),
		BackgroundTransparency = 1,
		label,
	}
end

return LoadingSpinner
