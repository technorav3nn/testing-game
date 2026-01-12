local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create
local source = vide.source
local changed = vide.changed

type Prop<T> = (() -> T) | T

export type Props = {
	Size: Prop<UDim2>?,
	Position: Prop<UDim2>?,
	AnchorPoint: Prop<Vector2>?,

	BgColor: Prop<Color3>?,
	TextColor: Prop<Color3>?,
	CornerRadius: Prop<UDim>?,
	BorderColor: Prop<Color3>?,

	Text: Prop<string>?,

	Activated: (() -> ())?,

	[number]: any,
}

local function Button(props: Props)
	local guiState = source(Enum.GuiState.Idle)

	return create "TextButton" {
		Size = props.Size or UDim2.new(1, 0, 0, 24),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = props.BgColor or theme.background.primary,
		TextColor3 = props.TextColor or theme.colors.inverted,
		AutoButtonColor = true,

		Activated = props.Activated,
		Text = props.Text or "Button",
		TextScaled = true,
		FontFace = theme.fonts.sans,
		changed("GuiState", function(state)
			guiState(state)
		end),

		create "UICorner" {
			CornerRadius = props.CornerRadius or theme.radii.rounded,
		},
		create "UIStroke" {
			Color = props.BorderColor or theme.colors.primary,
			Thickness = theme.stroke.thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		},

		unpack(props),
	}
end

return Button
