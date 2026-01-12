local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Iris = require(ReplicatedStorage.Packages.Iris)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Network = require(ReplicatedStorage.Network)
local template = require(ReplicatedStorage.Data.DataTemplate)

local trove = Trove.new()
local players = Players:GetPlayers()

-- avoids calling :GetPlayers() every frame lol
Players.PlayerAdded:Connect(function()
	players = Players:GetPlayers()
end)

Players.PlayerRemoving:Connect(function()
	players = Players:GetPlayers()
end)

local function getPlayerFromName(name: string): Player?
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Name == name then
			return plr
		end
	end
	return nil
end

local PunishmentPanel = {
	open = false,
	player = nil :: Player?,
}

function PunishmentPanel.Render()
	local player = PunishmentPanel.player :: Player?

	local selectedPlayerName = Iris.State(if player then player.Name else nil)
	local selectedPunishment = Iris.State("Kick")
	local reason = Iris.State("")
	local banLength = Iris.State(1)

	local function punishUser()
		local punishment: template.Punishment = {
			reason = reason:get(),
			issuedBy = player and player.UserId or nil,
			issuedAt = os.time(),
			duration = if selectedPunishment:get() == "Ban" then banLength:get() * 86400 else nil,
			type = string.lower(selectedPunishment:get()),
			isApiBan = false,
			privateReason = nil,
		}

		local success, result = Network.moderation.PunishPlayer:request(punishment):await()

		if not success then
			warn("Failed to punish player:", result)
			return
		end

		trove:Destroy()
	end

	local window = Iris.Window({ "Punishment Panel" })
	if window.closed() then
		PunishmentPanel.open = false
		PunishmentPanel.player = nil
		trove:Destroy()
		return
	end

	Iris.Text({
		`select a player to punish{if selectedPlayerName:get()
			then `: {selectedPlayerName:get()}`
			else "no player selected"}`,
	})
	local _combo = Iris.Combo({ "" }, { index = selectedPlayerName })
	do
		for _, plr in pairs(players) do
			Iris.Selectable({ plr.Name, plr.Name }, { index = selectedPlayerName })
		end
		Iris.End()
	end

	Iris.Text({ "type of punishment" })
	Iris.SameLine({})
	do
		-- Iris.RadioButton({ "Warn", "Warn" }, {})
		Iris.RadioButton({ "Kick", "Kick" }, { index = selectedPunishment })
		Iris.RadioButton({ "Server Ban", "Server Ban" }, { index = selectedPunishment })
		Iris.RadioButton({ "Ban", "Ban" }, { index = selectedPunishment })
		Iris.End()
	end

	Iris.Text({ "reason" })
	do
		Iris.InputText({ "" }, { text = reason })
	end

	if selectedPunishment:get() == "Ban" then
		Iris.Text({ "ban length" })
		do
			Iris.InputNum({
				"",
				1,
				1,
				60,
				"%d days",
			}, { number = banLength })
			if Iris.Button({ "permanent ban" }).clicked() then
				banLength:set(99999)
			end
		end
	end

	if Iris.Button({ "Submit" }).clicked() then
		punishUser()
		Iris.End()
		window.state.isOpened:set(false)
	end

	Iris.End()
end

return PunishmentPanel
