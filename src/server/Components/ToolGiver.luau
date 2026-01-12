local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local DataService = require(ServerScriptService.Server.Services.DataService)
local SoundUtils = require(ReplicatedStorage.Modules.Utils.SoundUtils)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ToolGiver = Component.new({ Tag = "TOOL_GIVER", Ancestors = { workspace } })

local PART_DEFAULT_COLOR = Color3.fromRGB(49, 137, 255)
local PART_SUCCESS_COLOR = Color3.fromRGB(0, 255, 0)
local PART_FAILURE_COLOR = Color3.fromRGB(255, 0, 0)

local WEAPON_BUY_LIMIT = 1
local CONSUMABLE_BUY_LIMIT = 2
local DEFAULT_BUY_LIMIT = 1

type ToolGiver = typeof(setmetatable(
	{} :: {
		_trove: typeof(Trove.new()),
		_prompt: ProximityPrompt,
		_billboardLabel: TextLabel,
		_configuration: Configuration,
		_toolToGive: Tool,
		_price: number,
		_buyLimit: number,
		Instance: Model,
		Notify: (self: ToolGiver, text: string, color: Color3) -> (),
	},
	ToolGiver
))

function ToolGiver.Construct(self: ToolGiver)
	self._trove = Trove.new()

	self._prompt = (self.Instance :: any).Attachment:FindFirstChildWhichIsA("ProximityPrompt")
	self._billboardLabel = (self.Instance :: any)
		:FindFirstChildWhichIsA("BillboardGui")
		:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	self._configuration = self.Instance:FindFirstChildWhichIsA("Configuration") :: Configuration

	local toolName = self._configuration:FindFirstChild("ToolToGive") :: StringValue
	assert(toolName, "ToolGiver: No ToolToGive found in Configuration")

	local tool = ServerStorage.Assets.Tools:FindFirstChild(toolName.Value, true) :: Tool
	assert(tool, `ToolGiver: Tool "{toolName.Value}" not found in ServerStorage.Assets.Tools`)
	self._toolToGive = tool

	if tool.Parent and tool.Parent:IsA("Folder") and tool.Parent.Name == "Weapons" then
		self._buyLimit = WEAPON_BUY_LIMIT
	elseif tool.Parent and tool.Parent:IsA("Folder") and tool.Parent.Name == "Consumables" then
		self._buyLimit = CONSUMABLE_BUY_LIMIT
	else
		self._buyLimit = DEFAULT_BUY_LIMIT
	end

	local priceValue = self._configuration:FindFirstChild("Price") :: NumberValue
	assert(priceValue, "ToolGiver: No Price found in Configuration")
	self._price = priceValue.Value

	-- Set the proximity prompt texts
	self._prompt.ActionText = `{self._toolToGive}`
	self._prompt.ObjectText = `${self._price}`

	-- Set the billboard text
	self._billboardLabel.Text = `{self._toolToGive.Name} - ${self._price}`
end

function ToolGiver.Start(self: ToolGiver)
	self._prompt.Triggered:Connect(function(player: Player)
		local success, cash = DataService:GetCash(player):await()
		if not success then
			warn(`ToolGiver: Failed to get cash for player {player.Name}`)
			return
		end
		local canAfford = cash >= self._price
		if not canAfford then
			self:Notify(`Not enough cash!`, PART_FAILURE_COLOR)
			return
		end

		local amountOfToolOwned = 0
		for _, v in ipairs(player.Backpack:GetChildren()) do
			if v:IsA("Tool") and v.Name == self._toolToGive.Name then
				amountOfToolOwned += 1
			end
		end
		if player.Character then
			for _, v in ipairs(player.Character:GetChildren()) do
				if v:IsA("Tool") and v.Name == self._toolToGive.Name then
					amountOfToolOwned += 1
				end
			end
		end

		if amountOfToolOwned >= self._buyLimit then
			self:Notify(`You cant buy anymore of this!`, PART_FAILURE_COLOR)
			return
		end

		local removeSuccess = DataService:RemoveCash(player, self._price):await()
		if not removeSuccess then
			warn(`ToolGiver: Failed to remove cash for player {player.Name}`)
			self:Notify(`Purchase failed!`, PART_FAILURE_COLOR)
			return
		end

		local tool = self._toolToGive:Clone()
		tool.Parent = player.Backpack

		self:Notify(`Purchased {self._toolToGive.Name}!`, PART_SUCCESS_COLOR)
	end)
end

function ToolGiver.Notify(self: ToolGiver, text: string, color: Color3)
	local part = self.Instance:FindFirstChild("Part") :: BasePart
	part.Color = color
	self._billboardLabel.Text = text
	self._prompt.Enabled = false

	if color == PART_FAILURE_COLOR then
		SoundUtils:PlaySound({
			id = SoundUtils.CommonSounds.Error,
			volume = 0.5,
			source = part,
		})
	end

	task.delay(1, function()
		self._billboardLabel.Text = `{self._toolToGive.Name} - ${self._price}`
		part.Color = PART_DEFAULT_COLOR
		self._prompt.Enabled = true
	end)
end

function ToolGiver.Destroy(self: ToolGiver)
	self._trove:Destroy()
end

return ToolGiver
