local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lyra = require(ReplicatedStorage.Packages.Lyra)
local Replica = require(ReplicatedStorage.Packages._Index["azutreo_replica@1.0.1"].replica.ReplicaServer)
local Signal = require(ReplicatedStorage.Packages.Signal)
local template = require(ReplicatedStorage.Data.DataTemplate)

local Promise = require(ReplicatedStorage.Packages["_Index"]["paradoxum-games_lyra@0.6.0"].lyra.Promise)

type DataService = {

	replicas: { Replica.Replica },
	store: typeof(Lyra.createPlayerStore({
		template = template.profileTemplate,
		name = "PlayerData",
		schema = function()
			return true
		end,
	})),
	isReady: boolean,
	playerDataChangedSignals: { Signal.Signal<template.Profile, template.Profile> },

	NewPlayerDataLoaded: typeof(Signal.new()),
	PlayerDataChanged: typeof(Signal.new()),
	Ready: typeof(Signal.new()),

	GetPlayerDataChangedSignal: (
		self: DataService,
		player: Player
	) -> Signal.Signal<template.Profile, template.Profile>,

	Init: (self: DataService) -> (),
	SetupEvents: (self: DataService) -> (),
	SetupReplica: (self: DataService, player: Player) -> (),

	GetData: (self: DataService, player: Player) -> Promise.TPromise<template.Profile>,
	GiveCash: (self: DataService, player: Player, amount: number) -> Promise.TPromise<boolean>,
	RemoveCash: (self: DataService, player: Player, amount: number) -> Promise.TPromise<boolean>,
	SetCash: (self: DataService, player: Player, amount: number) -> Promise.TPromise<boolean>,
}

local DataService = {
	replicas = {},
	isReady = false,
	playerDataChangedSignals = {},
	NewPlayerDataLoaded = Signal.new() :: typeof(Signal.new()),
	PlayerDataChanged = Signal.new() :: typeof(Signal.new()),
	Ready = Signal.new() :: typeof(Signal.new()),
} :: DataService

function DataService:Init()
	local function syncWithClient(key: string, newData: template.Profile, oldData: template.Profile)
		local player = Players:GetPlayerByUserId(assert(tonumber(key)))

		if not player then
			return
		end

		local replica = self.replicas[player.UserId]
		if not replica then
			return
		end
		if not oldData then
			-- first time, replica is already set before so dont need to set anything
			return
		end

		-- only send changes
		if newData.Cash ~= oldData.Cash then
			replica:Set({ "Cash" }, newData.Cash)
		end
		-- if not Tables.deepEquals(newData.inventory, oldData.inventory) then
		--     changes.inventory = newData.inventory
		-- end
		self:GetPlayerDataChangedSignal(player):Fire(newData, oldData)
	end

	local store = Lyra.createPlayerStore({
		name = "PlayerData",
		template = template.profileTemplate,
		schema = function(data)
			local ok, cause = template.profileSchema:matches(data)
			return ok, cause:formatErr()
		end,
		changedCallbacks = {
			syncWithClient :: (string, any, any) -> any,
		},
	})
	self.store = store
	DataService:SetupEvents()

	return self
end

function DataService:GetData(player: Player)
	return self.store:get(player)
end

function DataService:GetPlayerDataChangedSignal(player: Player)
	return self.playerDataChangedSignals[player.UserId]
end

function DataService:SetupEvents()
	Players.PlayerAdded:Connect(function(player)
		self.playerDataChangedSignals[player.UserId] = Signal.new()
		self.store:loadAsync(player)
		self.NewPlayerDataLoaded:Fire(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local replica = self.replicas[player.UserId]
		if replica then
			replica:Destroy()
			self.replicas[player.UserId] = nil
		end
		self.store:unloadAsync(player)
		self.playerDataChangedSignals[player.UserId]:Destroy()
		self.playerDataChangedSignals[player.UserId] = nil
	end)

	local ReplicaNewReadyPlayer = (Replica.NewReadyPlayer :: any) :: RBXScriptSignal
	ReplicaNewReadyPlayer:Connect(function(player: Player)
		self:SetupReplica(player)
	end)

	game:BindToClose(function()
		self.store:closeAsync()
	end)

	self.isReady = true
	self.Ready:Fire()
end

function DataService:SetupReplica(player: Player)
	local data = self.store:getAsync(player)
	local token = Replica.Token(tostring(player.UserId))

	local replica = Replica.New({
		Token = token :: any,
		Data = table.clone(data),
	})
	self.replicas[player.UserId] = replica

	-- wait until player is ready
	repeat
		task.wait()
	until player:IsDescendantOf(Players)

	replica:Subscribe(player)
	replica:Replicate()

	print(`Replica: loaded for {player.Name}!`)
end

-- Data Functions
function DataService:GiveCash(player: Player, amount: number): Promise.TPromise<boolean>
	local store = self.store
	return store:update(player, function(data)
		data.Cash += amount
		return true
	end)
end

function DataService:RemoveCash(player: Player, amount: number): Promise.TPromise<boolean>
	local store = self.store
	return store:update(player, function(data)
		data.Cash -= amount
		return true
	end)
end

function DataService:SetCash(player: Player, amount: number): Promise.TPromise<boolean>
	local store = self.store
	return store:update(player, function(data)
		data.Cash = amount
		return true
	end)
end

return DataService
