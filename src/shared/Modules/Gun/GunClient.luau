local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require("./GunConfigs/_types")

-- local DOT_ICON = "rbxassetid://3259050989" -- a small dot icon for the mouse cursor

local GunClient = {}
GunClient.__index = GunClient

if RunService:IsServer() then
	error("GunClient should not be required on the server")
end

export type GunServerProps = {
	_trove: typeof(Trove.new()),
	config: Types.GunConfig,
	tool: Tool,
	cursorImageLabel: ImageLabel?,

	ReloadRemoteFunction: RemoteFunction,
	FireRemoteFunction: RemoteFunction,
}

export type GunClient = typeof(setmetatable({} :: GunServerProps, GunClient))

function GunClient.new(tool: Tool): GunClient
	local configMod = script.Parent.GunConfigs:FindFirstChild(tool.Name) :: ModuleScript?
	if not configMod then
		error("No gun config found for tool: " .. tool.Name)
	end

	local self = setmetatable({}, GunClient) :: GunClient
	self._trove = Trove.new()
	self.config = require(configMod) :: Types.GunConfig
	self.tool = tool

	self.FireRemoteFunction = tool:WaitForChild("Fire") :: RemoteFunction
	self.ReloadRemoteFunction = tool:WaitForChild("Reload") :: RemoteFunction

	self._trove:Add(self.tool.Activated:Connect(function()
		self:OnActivated()
	end))
	self._trove:Add(self.tool.Equipped:Connect(function()
		self:OnEquipped()
	end))
	self._trove:Add(self.tool.Unequipped:Connect(function()
		self:OnUneqipped()
	end))
	self._trove:Add(UserInputService.InputBegan:Connect(function(input: InputObject)
		self:OnUISKeyDown(input)
	end));
	((Players.LocalPlayer.Character :: Model):FindFirstChild("Humanoid") :: Humanoid)
		:GetPropertyChangedSignal("Health")
		:Connect(function()
			print("test1234")
			if ((Players.LocalPlayer.Character :: Model):FindFirstChild("Humanoid") :: Humanoid).Health > 0 then
				return
			end
			print("humanoid died, unequipping gun client")
			-- wait until humanoid is alive
			Players.LocalPlayer.CharacterAdded:Wait()
			self:OnUneqipped()
		end)

	return self
end

function GunClient.OnEquipped(_self: GunClient)
	print("running OnEquipped")
	local mouse = Players.LocalPlayer:GetMouse()

	Players.LocalPlayer.PlayerGui.ScreenGui.Enabled = true
	UserInputService.MouseIconEnabled = false

	RunService:BindToRenderStep("UpdateCursor", Enum.RenderPriority.Camera.Value, function()
		print("updating cursor position")
		local screenGui = Players.LocalPlayer.PlayerGui.ScreenGui
		local imageLabel = screenGui.CustomCursor
		imageLabel.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	end)
end

function GunClient.OnUneqipped(_self: GunClient)
	RunService:UnbindFromRenderStep("UpdateCursor")
	UserInputService.MouseIconEnabled = true

	local screenGui = Players.LocalPlayer.PlayerGui.ScreenGui
	screenGui.Enabled = false
end

function GunClient.OnUISKeyDown(self: GunClient, input: InputObject)
	if input.KeyCode == Enum.KeyCode.R then
		self.ReloadRemoteFunction:InvokeServer()
	end
end

function GunClient.OnActivated(self: GunClient)
	print("running OnActivated")
	local mouse = Players.LocalPlayer:GetMouse()
	local mousePos = mouse.Hit.Position

	if self.tool:GetAttribute(Types.possibleAttributes.Ammo) == 0 then
		if self.tool:GetAttribute(Types.possibleAttributes.IsReloading) then
			print("Already reloading...")
			return
		end
		-- auto-reload when firing with no ammo
		print("Out of ammo, reloading...")
		print(self.ReloadRemoteFunction:InvokeServer())
		return
	end

	self.FireRemoteFunction:InvokeServer(mousePos)
end

function GunClient.Destroy(self: GunClient)
	self._trove:Destroy()
end

return GunClient
