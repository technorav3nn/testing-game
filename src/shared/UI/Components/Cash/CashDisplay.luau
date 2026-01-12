local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFrame = require("../../Components/Base/Frame")
local playerData = require("../../Stores/PlayerData")
local px = require("../../Composables/usePx")
local theme = require("../../Theme")

local Formatters = require(ReplicatedStorage.Modules.Utils.Formatters)
local vide = require(ReplicatedStorage.Packages.Vide)
local videCharm = require(ReplicatedStorage.Packages.VideCharm)

local create = vide.create
local useAtom = videCharm.useAtom

local function CashDisplay()
	local cash = useAtom((playerData.cashAtom :: any) :: () -> number?)

	return UIFrame {
		Name = "CashDisplay",
		Size = px.offset(80, 30),
		Position = px.udim2(0, 10, 1, -10),
		AnchorPoint = Vector2.new(0, 1),
		create "TextLabel" {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = function()
				return `${Formatters:FormatNumber((cash :: () -> number)())}`
			end,
			TextColor3 = theme.colors.primary,
			FontFace = theme.fonts.sansBold,
			TextSize = 25,
			create "UIStroke" {
				Color = theme.background.accented,
				Thickness = theme.stroke.thickness,
			},
		},
		create "UIStroke" {
			Color = theme.background.accented,
			Thickness = theme.stroke.thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		},
	}
end

return CashDisplay
