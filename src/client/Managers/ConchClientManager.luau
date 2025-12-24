local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Conch = require(ReplicatedStorage.Packages.Conch)
local ConchUI = require(ReplicatedStorage.Packages.ConchUI)
local state = require(ReplicatedStorage.Packages._Index["alicesaidhi_conch-ui@0.3.1"]["conch-ui"].src.state)

local ConchClientManager = {}

local keybindDown = false

function ConchClientManager.OnStart()
	Conch.register_default_commands()
	Conch.initiate_default_lifecycle()
	ConchUI.mount()

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftControl then
			keybindDown = true
		elseif input.KeyCode == Enum.KeyCode.RightBracket then
			if not keybindDown then
				return
			end
			local isOpened = state.opened()
			state.opened(not isOpened)
			state.focused(state.opened())
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftControl then
			keybindDown = false
		end
	end)

	print("[Conch]: Ready!")
end

return ConchClientManager
