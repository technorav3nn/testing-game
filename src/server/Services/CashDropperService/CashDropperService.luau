local CashDrop = require("./CashDrop")

local CashDropperService = {}

function CashDropperService:DropCash(amount: number, cframe: CFrame, anchored: boolean)
	local drop = CashDrop.new(amount, cframe, anchored)
	return drop
end

return CashDropperService
