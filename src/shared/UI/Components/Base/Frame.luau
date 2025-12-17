local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local create = vide.create

local function Frame(props: {
	Name: string,
	Position: vide.Source<UDim2> | UDim2,
	Size: vide.Source<UDim2> | UDim2,
	AnchorPoint: Vector2?,
	[number]: vide.Source<any> | any,
})
	return create "Frame" {
		Name = props.Name,
		Position = props.Position,
		Size = props.Size,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = theme.background.elevated,
		create "UICorner" {
			CornerRadius = theme.radii.rounded,
		},
		unpack(props),
	}
end

return Frame
