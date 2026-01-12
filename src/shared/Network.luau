local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remo = require(ReplicatedStorage.Packages.Remo)
local t = require(ReplicatedStorage.Packages._Index["osyrisrblx_t@3.1.1"].t)

local template = require(ReplicatedStorage.Data.DataTemplate)

-- Luau
type Remotes = {
	-- An event processed on the client
	moderation: {
		PunishPlayer: Remo.ServerAsync<(template.Punishment), (boolean, string)>,
	},
	cash: {
		DropCash: Remo.ServerAsync<(number), (number)>,
	},
	weaponSystem: {
		FireWeapon: Remo.ClientToServer<(string, Vector3)>,
		ReloadWeapon: Remo.ClientToServer<(string)>,
	},
}

local Network = Remo.createRemotes({
	moderation = Remo.namespace({
		PunishPlayer = Remo.remote(t.table).returns(t.boolean),
	}),
	cash = Remo.namespace({
		DropCash = Remo.remote(t.number).returns(t.number),
	}),
	weaponSystem = Remo.namespace({
		FireWeapon = Remo.remote(t.string, t.Vector3),
		ReloadWeapon = Remo.remote(t.string),
	}),
} :: any)

return (Network :: any) :: Remotes
