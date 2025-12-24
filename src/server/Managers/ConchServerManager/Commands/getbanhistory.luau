local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)

local function pagesToTable(pages: BanHistoryPages)
	local resultTable = {}
	local currentPage = pages:GetCurrentPage()

	while true do
		for _, item in ipairs(currentPage) do
			table.insert(resultTable, item)
		end

		if pages.IsFinished then
			break
		end

		pages:AdvanceToNextPageAsync()
		currentPage = pages:GetCurrentPage()
	end

	return resultTable
end

local KickCommand = {}

function KickCommand.Register()
	Conch.register("kick", {
		arguments = function()
			return Conch.args.userid("user_id", "player 's !! USERID !! to get history from")
		end,
		permissions = { "super-user" },
		callback = function(userId)
			local success, historyPages = pcall(Players.GetBanHistoryAsync, Players, userId)
			if not success then
				Conch.log("error", `failed to get ban history for userId {userId}: {historyPages}`)
				return
			end

			local history = pagesToTable(historyPages)
			for _, record in ipairs(history) do
				Conch.log(
					"info",
					`Ban Record - UserId: {record.UserId}, DisplayReason: {record.DisplayReason}, PrivateReason: {record.PrivateReason}, Duration: {record.Duration}, CreatedAt: {record.CreatedAt}, ExcludeAltAccounts: {tostring(
						record.ExcludeAltAccounts
					)}`
				)
			end
		end,
	})
end

return KickCommand
