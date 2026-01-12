local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create

local function Frame(props: {
	Name: string,
	Position: vide.Source<UDim2> | UDim2,
	Size: vide.Source<UDim2> | UDim2,
	AnchorPoint: Vector2?,
	BackgroundColor3: vide.Source<Color3> | Color3?,
	MouseEnter: (vide.Source<any> | any)?,
	MouseLeave: (vide.Source<any> | any)?,
	Rounded: (vide.Source<boolean> | boolean)?,
	ClipsDescendants: (vide.Source<boolean> | boolean)?,

	[any]: vide.Source<any> | any,
})
	props.Rounded = props.Rounded or true
	return create "Frame" {
		Name = props.Name,
		Position = props.Position,
		Size = props.Size,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = props.BackgroundColor3 or theme.background.elevated,
		unpack(if props.Rounded
			then {
				create "UICorner" {
					CornerRadius = theme.radii.rounded,
				},
			}
			else {}),
		MouseEnter = props.MouseEnter,
		MouseLeave = props.MouseLeave,
		unpack(props),
	}
end

return Frame
