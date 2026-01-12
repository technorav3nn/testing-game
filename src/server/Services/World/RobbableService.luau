local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CashDropperService = require("../../Services/CashDropperService")
local Cooldown = require(ReplicatedStorage.Modules.Utils.Cooldowns)

local robbableCooldown = Cooldown.new("Robbable")

local ROBBABLE_WAIT_TIME = if RunService:IsStudio() then 20 else 120
local random = Random.new()

local function getRandomCashAmount()
	return random:NextInteger(50, 200)
end

local RobbableService = {}

function RobbableService.OnStart()
	for _, register in ipairs(workspace.CashRegisters:GetChildren()) do
		if not register:GetAttribute("UniqueId") then
			register:SetAttribute("UniqueId", HttpService:GenerateGUID())
		end

		local prompt = (register :: any).MeshPart.Attachment.ProximityPrompt :: ProximityPrompt

		prompt.Triggered:Connect(function()
			RobbableService.OnPromptTriggered(register, prompt)
		end)
	end
end

function RobbableService.OnPromptTriggered(register: Instance, prompt: ProximityPrompt)
	local oldActionText = prompt.ActionText

	local part = (register :: any).MeshPart :: MeshPart
	local particles = (part :: any).CooldownParticles :: ParticleEmitter

	local id = register:GetAttribute("UniqueId") :: string
	local ready = robbableCooldown:Check(id)

	if not ready then
		return
	end

	for _ = 1, 4 do
		local amount = getRandomCashAmount()
		CashDropperService:DropCash(amount, part.CFrame + Vector3.new(0, 0, -4), false)
	end

	prompt.ActionText = `{prompt.ActionText} (Cooldown)`
	particles.Enabled = true

	robbableCooldown:Add(id, ROBBABLE_WAIT_TIME, function()
		prompt.ActionText = oldActionText
		particles.Enabled = false
	end)
end

return RobbableService
