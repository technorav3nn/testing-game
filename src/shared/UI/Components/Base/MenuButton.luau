local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lucide = require(ReplicatedStorage.Packages.LucideIcons)
local px = require("../../Composables/usePx")
local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create
local source = vide.source
local spring = vide.spring

local function Button(props: {
	Position: UDim2 | (() -> UDim2),
	Size: UDim2 | (() -> UDim2),
	AnchorPoint: Vector2?,
	Text: string?,
	Icon: lucide.Asset?,
	IconColor: Color3?,
	BackgroundColor3: Color3?,
} & any)
	local pressed = source(false)
	local hovered = source(false)

	return create "TextButton" {
		Position = props.Position,
		Size = spring(function()
			local size = (typeof(props.Size) == "function" and props.Size() or props.Size) :: UDim2
			if pressed() then
				return UDim2.new(size.X.Scale * 0.9, size.X.Offset * 0.9, size.Y.Scale * 0.9, size.Y.Offset * 0.9)
			elseif hovered() and not pressed() then
				return UDim2.new(size.X.Scale * 1.1, size.X.Offset * 1.1, size.Y.Scale * 1.1, size.Y.Offset * 1.1)
			else
				return size
			end
		end, 0.2, 1.3),
		MouseButton1Down = function()
			pressed(true)
		end,
		MouseButton1Up = function()
			pressed(false)
		end,
		MouseEnter = function()
			hovered(true)
		end,
		MouseLeave = function()
			hovered(false)
		end,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = props.BackgroundColor3 or theme.background.elevated,
		Text = (props.Text and not props.Icon) and props.Text or "",
		TextScaled = true,
		TextColor3 = theme.colors.neutral,
		FontFace = theme.fonts.sansSemiBold,
		create "UICorner" {
			CornerRadius = theme.radii.rounded,
		},
		create "UIStroke" {
			Color = theme.background.accented,
			Thickness = theme.stroke.thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		},
		create "UITextSizeConstraint" {
			MaxTextSize = 24,
			MinTextSize = 12,
		},
		create "UIPadding" {
			PaddingTop = UDim.new(0, 7),
			PaddingBottom = UDim.new(0, 7),
			PaddingLeft = UDim.new(0, 7),
			PaddingRight = UDim.new(0, 7),
		},
		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			SortOrder = Enum.SortOrder.LayoutOrder,
			-- Padding = UDim.new(0, 8),
		},
		unpack(props.Icon and {
			create "ImageLabel" {
				Name = "Icon",
				Position = UDim2.fromScale(0.5, 0.3),
				Size = px.offset(24, 24),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Visible = props.Icon ~= nil,
				Image = props.Icon.Url,
				ImageRectSize = props.Icon.ImageRectSize,
				ImageRectOffset = props.Icon.ImageRectOffset,
				ScaleType = Enum.ScaleType.Fit,
				ImageColor3 = props.IconColor or theme.colors.neutral,
			},
		} or {}),
		unpack((props.Text and props.Icon) and {
			create "TextLabel" {
				Name = "Text",
				BackgroundTransparency = 1,
				Text = props.Text,
				TextScaled = true,
				TextColor3 = theme.colors.neutral,
				FontFace = theme.fonts.sansBold,
				Size = px.udim2(0, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				create "UIStroke" {
					Color = theme.stroke.color,
					Thickness = 1,
				},
			},
		} or {}),
		unpack(props),
	}
end

return Button
