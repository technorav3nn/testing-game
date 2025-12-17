local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuButton = require("./Components/Base/MenuButton")
-- local UIFrame = require("./Components/Base/Frame")
local CashDisplay = require("./Components/Cash/CashDisplay")
local theme = require("./Theme")

local lucide = require(ReplicatedStorage.Packages.LucideIcons)
local px = require("./Composables/usePx")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create

local function App()
	px.usePx()

	return create "ScreenGui" {
		Name = "App",
		IgnoreGuiInset = true,

		-- Menu buttons
		create "Frame" {
			Name = "ListContainer",
			Position = px.udim2(0, 0, 0.5, 0),
			Size = px.offset(100, 100),
			AnchorPoint = Vector2.new(0.2, 0.5),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = px.udim(0, 10),
			},
			MenuButton {
				Position = px.offset(0, 0),
				Size = px.offset(50, 50),
				Icon = lucide.GetAsset("shopping-basket", 48),
				IconColor = theme.colors.neutral,
				Text = "Shop",
			},
		},

		-- Cash Display in bottom-right corner
		CashDisplay(),
	}
end
return App
