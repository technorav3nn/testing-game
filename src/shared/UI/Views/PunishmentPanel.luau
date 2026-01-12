local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Button = require("../Components/Base/Button")
local Frame = require("../Components/Base/Frame")
local px = require("../Composables/usePx")
local theme = require("../Theme")

local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create
local source = vide.source

local function PunishmentPanel(player: Player)
	px.usePx()
	local dragEnabled = source(true)
	local isDragging = source(false)

	return create "ScreenGui" {
		Name = "PunishmentPanel",
		Frame {
			Name = "PunishmentPanel",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 400, 0, 250),
			Rounded = false,
			create "UIStroke" {
				Color = theme.stroke.color,
				Thickness = theme.stroke.thickness,
			},
			Frame {
				Name = "Topbar",
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.fromScale(0, 0),
				BackgroundColor3 = theme.background.accented,
				Rounded = false,

				create "UIPadding" {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				},

				Button {
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(1, 0.5),
					AnchorPoint = Vector2.new(1, 0.5),
					Text = "×",
					BgColor = theme.background.error,
					BorderColor = theme.colors.error,
					TextColor = theme.colors.inverted,
					create "UIAspectRatioConstraint" {
						AspectRatio = 1,
					},
				},

				create "TextLabel" {
					Text = "PUNISHMENT PANEL",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					TextColor3 = theme.colors.neutral,
					FontFace = theme.fonts.sansSemiBold,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					create "UIPadding" {
						PaddingLeft = UDim.new(0, 3),
					},
				},

				create "Frame" {
					Name = "RoundedCover",
					Position = UDim2.new(0, -4, 1, 4),
					Size = UDim2.fromScale(0.2, 0.2),
					AnchorPoint = Vector2.new(0, 1),
					BackgroundColor3 = theme.background.accented,
					ZIndex = -1,
				},

				create "Frame" {
					Name = "RoundedCover",
					Position = UDim2.new(1, 4, 1, 4),
					Size = UDim2.fromScale(0.2, 0.2),
					AnchorPoint = Vector2.new(1, 1),
					BackgroundColor3 = theme.background.accented,
					ZIndex = -1,
				},

				MouseEnter = function()
					dragEnabled(true)
				end,
				MouseLeave = function()
					if isDragging() then
						return
					end
					dragEnabled(false)
				end,
			},
			Frame {
				Name = "BottomCorner",
				Rounded = true,
				Size = UDim2.fromScale(1, 0.15),
				Position = UDim2.fromScale(0, 0.85),
			},

			create "Frame" {
				Name = "Container",
				Size = UDim2.new(1, 0, 1, -30),
				AnchorPoint = Vector2.new(1, 1),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 1),
			},

			create "UIDragDetector" {
				Enabled = function()
					return dragEnabled()
				end,
				DragStart = function()
					isDragging(true)
				end,
				DragEnd = function()
					isDragging(false)
				end,
			},
		},
	}
end

return PunishmentPanel
