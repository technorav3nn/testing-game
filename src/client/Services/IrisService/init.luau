local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Iris = require(ReplicatedStorage.Packages.Iris)

local IrisService = {
	punishmentPanelOpen = false,
}

function IrisService.OnStart() end

function IrisService.ShowPunishmentPanel(player: Player?) end

function IrisService.HidePunishmentPanel() end

return IrisService
