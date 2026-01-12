local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local clickSound = ReplicatedStorage.Assets.Sounds.UIClickSound
local hoverSound = ReplicatedStorage.Assets.Sounds.UIHoverSound

local function createEventsForButton(button: TextButton | ImageButton)
	button.MouseButton1Down:Connect(function()
		SoundService:PlayLocalSound(clickSound)
	end)
	button.MouseButton1Up:Connect(function()
		SoundService:PlayLocalSound(clickSound)
	end)
	button.MouseEnter:Connect(function()
		SoundService:PlayLocalSound(hoverSound)
	end)
end

for _, v in ipairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
	if v:IsA("TextButton") or v:IsA("ImageButton") then
		createEventsForButton(v)
	end
end

Players.LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
	if v:IsA("TextButton") or v:IsA("ImageButton") then
		createEventsForButton(v)
	end
end)
