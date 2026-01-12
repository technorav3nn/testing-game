local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local SoundUtils = require(ReplicatedStorage.Modules.Utils.SoundUtils)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TypeUtils = require(ReplicatedStorage.Modules.Utils.TypeUtils)

type getkey<T, V> = TypeUtils.getkey<T, V>

type FoodItemAttributes = {
	MaxUses: number,
	StatRestore: number,
	Type: "health" | "stamina",
	TimesUsed: number,
}

local FoodItem = Component.new({ Tag = "FOOD_ITEM", Ancestors = { workspace, Players } })

type FoodItem = typeof(setmetatable(
	{} :: {
		_trove: typeof(Trove.new()),
		Instance: Tool,
	},
	FoodItem
))

function FoodItem.Construct(self: FoodItem)
	self._trove = Trove.new()
	local tool = self.Instance :: Tool
	print("FoodItem component constructed for tool:", tool.Name)

	self._trove:Connect(tool.Equipped, function()
		local char = tool.Parent :: any
		local m6d = Instance.new("Motor6D")
		m6d.Part0 = char["Right Arm"] :: BasePart
		m6d.Part1 = (tool :: any).Handle :: BasePart
		m6d.Parent = char["Right Arm"] :: BasePart

		local animation = tool:FindFirstChild("EquippedAnimation") :: Animation
		if not animation then
			warn("No equipped animation found for food item:", tool.Name)
			return
		end

		local player = Players:GetPlayerFromCharacter(tool.Parent :: Model) :: Player

		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local animTrack = (humanoid:FindFirstChildOfClass("Animator") :: Animator):LoadAnimation(animation)

		animTrack.Looped = true
		animTrack.Priority = Enum.AnimationPriority.Idle
		animTrack:Play()

		self._trove:Add(function()
			animTrack:Stop()
		end)
	end)
	self._trove:Connect(tool.Activated, function()
		print("FoodItem tool activated:", tool.Name)
		local player = Players:GetPlayerFromCharacter(tool.Parent :: Model)
		if not player then
			return
		end

		local type = tool:GetAttribute("Type") :: getkey<FoodItemAttributes, "Type">
		if not type then
			return
		end

		local maxUses = tool:GetAttribute("MaxUses") :: getkey<FoodItemAttributes, "MaxUses">
		local timesUsed = tool:GetAttribute("TimesUsed") :: getkey<FoodItemAttributes, "TimesUsed">

		local useSound = tool:FindFirstChild("UseSound") :: Sound
		if useSound then
			SoundUtils:PlaySound({
				source = tool:FindFirstChild("Handle") :: BasePart,
				sound = useSound,
				volume = 0.5,
			})
		end

		local statRestore = tool:GetAttribute("StatRestore") :: getkey<FoodItemAttributes, "StatRestore">
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

		if not humanoid then
			return
		end

		local animation = tool:FindFirstChild("ActivatedAnimation") :: Animation
		if not animation then
			warn("No animation found for food item:", tool.Name)
			return
		end

		local animTrack = (humanoid:FindFirstChildOfClass("Animator") :: Animator):LoadAnimation(animation)
		animTrack.Looped = false
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack:Play()

		if type == "health" then
			humanoid.Health = math.clamp(humanoid.Health + statRestore, 0, humanoid.MaxHealth)
		elseif type == "stamina" then
			-- TOOD: Implement stamina restoration
			warn("Stamina restoration not implemented yet")
		end
		local newTimesUsed = timesUsed + 1
		tool:SetAttribute("TimesUsed", newTimesUsed)

		animTrack.Ended:Wait()
		if newTimesUsed >= maxUses then
			tool:Destroy()
		end
	end)
	self._trove:Connect(tool.Unequipped, function()
		self._trove:Clean()
	end)
end

function FoodItem.Stop(self: FoodItem)
	self._trove:Destroy()
end

return FoodItem
