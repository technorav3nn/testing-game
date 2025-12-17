local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local WalletDropCashEvent = require(ReplicatedStorage.Network.Events.WalletDropCash):Client()

local Button = require("../Components/Base/Button")
local UIFrame = require("../Components/Base/Frame")
local theme = require("../Theme")

local px = require("../Composables/usePx")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create
local action = vide.action
local source = vide.source
local cleanup = vide.cleanup

local function WalletView()
	local text = source(nil) :: vide.source<string?>

	local function onClick()
		if not text() then
			StarterGui:SetCore("SendNotification", {
				Title = "Cannot Drop Cash",
				Text = "Enter a cash amount to drop!",
				Duration = 3.5,
			})
			return
		end

		local amount = tonumber(text() :: string) :: number
		WalletDropCashEvent:Fire(amount)

		StarterGui:SetCore("SendNotification", {
			Title = "Dropped Cash",
			Text = `Succesfully dropped ${text()} cash!`,
			Duration = 3.5,
		})
	end

	return create "ScreenGui" {
		Name = "WalletView",
		UIFrame {
			create "UIStroke" {
				Color = theme.background.elevated,
				Thickness = theme.stroke.thickness,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			},
			Name = "WalletFrame",
			Position = px.udim2(0.5, 0, 0.5, 0),
			Size = px.udim2(0.3, 0, 0.2, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			create "TextLabel" {
				Text = "Wallet",
				Position = px.udim2(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 1),
				TextSize = 24,
				FontFace = theme.fonts.sansSemiBold,
				TextColor3 = theme.colors.neutral,
				create "UIStroke" {},
			},
			create "CanvasGroup" {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				create "UIPadding" {
					PaddingTop = UDim.new(0.5, 0),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
				},
				create "UIListLayout" {
					Wraps = false,
					ItemLineAlignment = Enum.ItemLineAlignment.Stretch,
					VerticalFlex = Enum.UIFlexAlignment.None,
					Padding = UDim.new(0, 6),
				},
				create "TextBox" {
					BackgroundColor3 = theme.background.accented,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = px.udim2(0.8, 0, 0, 20),
					TextColor3 = theme.colors.neutral,
					Position = px.udim2(0.5, 0, 0.35, 0),
					TextScaled = true,
					create "UICorner" {
						CornerRadius = theme.radii.small,
					},
					create "UIStroke" {
						Color = theme.background.border,
						Thickness = theme.stroke.thickness,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					},
					action(function(_inst: Instance)
						local inst = _inst :: TextBox
						local conn = inst:GetPropertyChangedSignal("Text"):Connect(function()
							inst.Text = string.gsub(inst.Text, "[^%d%.%-]", "")
							text(inst.Text)
						end)

						cleanup(function()
							conn:Disconnect()
						end)
					end),
				},
				Button {
					Text = "Drop Cash",
					Activated = onClick,
				},
			},
		},
	}
end

return WalletView
