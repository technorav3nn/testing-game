local SUFFIXES = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
}

local function addCommas(number)
	local formatted = tostring(number)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

local function abbreviateNumber(number)
	local index = 1
	local num = math.abs(number) * 1.0
	while num >= 1000 and index < #SUFFIXES do
		num = num / 1000
		index = index + 1
	end

	local formatted = string.format("%.2f", num)

	formatted = string.gsub(formatted, "%.00$", "")
	formatted = string.gsub(formatted, "(%.%d)0$", "%1")

	if number < 0 then
		formatted = "-" .. formatted
	end

	return formatted .. SUFFIXES[index]
end

local Formatters = {}

function Formatters:FormatNumber(number: number, abbreviate: boolean?)
	if abbreviate then
		return abbreviateNumber(number)
	else
		return addCommas(number)
	end
end

return Formatters
