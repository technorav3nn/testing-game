local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local px = require("../../Composables/usePx")
local theme = require("../../Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local Promise = require(ReplicatedStorage.Packages.Promise)

local create = vide.create
local moneySound = ReplicatedStorage.Assets.Sounds:WaitForChild("MoneySound")

local function showCashNotification(amount: number)
	return vide.root(function()
		SoundService:PlayLocalSound(moneySound)

		local stroke = create "UIStroke" {}
		local label = create "TextLabel" {
			TextColor3 = amount >= 0 and theme.colors.primary or theme.colors.error,
			Text = function()
				local sign = if amount >= 0 then "" else "-"
				return `{sign}${math.abs(amount)}`
			end,
			TextSize = 24,
			Name = "CashNotification",
			Position = px.udim2(0, 10, 1, -50)(),
			Size = px.offset(80, 30),
			AnchorPoint = Vector2.new(0, 1),
			FontFace = theme.fonts.sansBold,
			BackgroundTransparency = 1,
			stroke,
		}

		local info = TweenInfo.new(2, Enum.EasingStyle.Quint)
		Promise.all({
			Promise.new(function(res, _, onCancel)
				local tween =
					TweenService:Create(label, info, { Position = px.udim2(0, 10, 1, -100)(), TextTransparency = 1 })
				tween.Completed:Connect(res)
				onCancel(function()
					tween:Cancel()
				end)
				tween:Play()
			end),
			Promise.new(function(res, _, onCancel)
				local tween = TweenService:Create(stroke, info, { Transparency = 1 })
				tween.Completed:Connect(res)
				onCancel(function()
					tween:Cancel()
				end)
				tween:Play()
			end),
		}):andThen(function()
			label:Destroy()
		end)

		label.Parent = Players.LocalPlayer.PlayerGui:FindFirstChild("App")
	end)()
end

return showCashNotification
