local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require("../../Services/DataService")
local Trove = require(ReplicatedStorage.Packages.Trove)

local CashDrop = {}
CashDrop.__index = CashDrop

export type CashDropProps = {
	_trove: typeof(Trove.new()),
	Amount: number,
	_CashDropInstance: Model,
}

export type CashDrop = typeof(setmetatable({} :: CashDropProps, CashDrop))

function CashDrop.new(amount: number, cframe: CFrame, anchored: boolean): CashDrop
	local self = setmetatable({}, CashDrop) :: CashDrop
	self._trove = Trove.new()

	self._CashDropInstance = self._trove:Add(ServerStorage.Assets.Cash.DroppedCash:Clone())
	local primaryPart = self._CashDropInstance.PrimaryPart :: BasePart
	primaryPart.CFrame = cframe
	primaryPart.Anchored = anchored
	-- Make it heavier
	primaryPart.CustomPhysicalProperties = PhysicalProperties.new(60, 0, 0, 0, 0)

	self._CashDropInstance.Parent = game.Workspace
	primaryPart:SetNetworkOwner(nil)

	self.Amount = amount

	self:_SetupBillboardGui()
	self:_SetupEvents()

	return self
end

function CashDrop:_SetupBillboardGui()
	local gui = (self._CashDropInstance :: any).MeshPart.Attachment.BillboardGui
	local label = gui.TextLabel :: TextLabel

	label.Text = `${self.Amount}`
end

function CashDrop._SetupEvents(self: CashDrop)
	local amount = self.Amount
	local prompt = (self._CashDropInstance :: any).MeshPart.Attachment.ProximityPrompt :: ProximityPrompt

	self._trove:Add(prompt.Triggered:Connect(function(player)
		prompt:Destroy()
		task.spawn(function()
			DataService:GiveCash(player, amount):await()
		end)
		self:Destroy()
	end))
end

-- Methods
function CashDrop.Destroy(self: CashDrop)
	self._trove:Destroy()
end

return CashDrop
