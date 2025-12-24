local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LoadingSpinner = require(ReplicatedStorage.UI.Components.Base.LoadingSpinner)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VideCharm = require(ReplicatedStorage.Packages.VideCharm)
local WeaponsSystem = require("../WeaponsSystem") :: any
local px = require("../../../UI/Composables/usePx")
local store = require("./Store")
local theme = require("../../../UI/Theme")
local vide = require(ReplicatedStorage.Packages.Vide)

local useAtom = VideCharm.useAtom
local create = vide.create
local cleanup = vide.cleanup
local source = vide.source

local function App()
	px.usePx()
	store.setupStore()

	local function isFirstPerson()
		local camera = workspace.CurrentCamera
		local distance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		return distance <= 0.75
	end

	local firstTime = source(true)
	local firstPerson = source(isFirstPerson())

	local trove = Trove.new()
	local cleanupTrove = Trove.new()

	local position = source(UDim2.new(1, -10, 1, -10))

	local function setupWeaponGui()
		local currentWeapon = WeaponsSystem.currentWeapon
		if not currentWeapon then
			return
		end

		local instance = currentWeapon.weaponInstance
		local ammoInMagazine = instance:GetAttribute("AmmoInMagazine")
		local totalAmmo = instance:GetAttribute("TotalAmmo")
		local isReloading = instance:GetAttribute("IsReloading")

		store.currentAmmoAtom(ammoInMagazine)
		store.totalAmmoAtom(totalAmmo)
		store.isReloadingAtom(isReloading)
		store.currentWeaponNameAtom(instance.Name)

		trove:Add(instance:GetAttributeChangedSignal("AmmoInMagazine"):Connect(function()
			local ammoInMagazine = instance:GetAttribute("AmmoInMagazine")
			store.currentAmmoAtom(ammoInMagazine)
		end))
		trove:Add(instance:GetAttributeChangedSignal("TotalAmmo"):Connect(function()
			local totalAmmo = instance:GetAttribute("TotalAmmo")
			store.totalAmmoAtom(totalAmmo)
		end))
		trove:Add(instance:GetAttributeChangedSignal("IsReloading"):Connect(function()
			local isReloading = instance:GetAttribute("IsReloading")
			store.isReloadingAtom(isReloading)
		end))
		trove:Add(RunService.Heartbeat:Connect(function(delta: number)
			local camera = workspace.CurrentCamera
			local distance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
			local isFp = isFirstPerson()
			firstPerson(isFp)
			if isFp then
				-- hide the gui in first person
				position(UDim2.new(1, -10, 1, -10))
				return
			end

			local screenPoint, inBounds =
				workspace.CurrentCamera:WorldToScreenPoint(instance:FindFirstChild("Handle").Position)
			-- move the gui to above and to the right of the weapon handle
			local offsetY = instance:GetAttribute("WeaponInfoOffsetY") or 30
			local offsetX = instance:GetAttribute("WeaponInfoOffsetX") or 30
			if not instance:GetAttribute("WeaponInfoOffsetY") then
				instance:SetAttribute("WeaponInfoOffsetY", offsetY)
			end
			if not instance:GetAttribute("WeaponInfoOffsetX") then
				instance:SetAttribute("WeaponInfoOffsetX", offsetX)
			end
			if not inBounds then
				position(UDim2.new(1, -10, 1, -10))
				return
			end
			local newScreenPoint = Vector2.new(screenPoint.X + offsetX, screenPoint.Y + offsetY)

			if firstTime() then
				-- dont lerp
				firstTime(false)
				position(UDim2.new(0, newScreenPoint.X, 0, newScreenPoint.Y))
			end
			position(position():Lerp(UDim2.new(0, newScreenPoint.X, 0, newScreenPoint.Y), 0.25 * (60 * delta)))
		end))
	end

	cleanup(function()
		store.cleanupStore()
		trove:Destroy()
		cleanupTrove:Destroy()
	end)

	setupWeaponGui()
	cleanupTrove:Add(WeaponsSystem.CurrentWeaponChanged:Connect(function()
		trove:Destroy()
		print(
			"Weapon changed, setting up weapon GUI: ",
			WeaponsSystem.currentWeapon and WeaponsSystem.currentWeapon.weaponInstance.Name
		)
		setupWeaponGui()
	end))

	local currentAmmo = useAtom(store.currentAmmoAtom)
	local totalAmmo = useAtom(store.totalAmmoAtom)
	local isReloading = useAtom(store.isReloadingAtom)
	local currentWeaponName = useAtom(store.currentWeaponNameAtom)

	return create "ScreenGui" {
		Name = "WeaponsSystemDisplay",
		Enabled = false,
		create "Frame" {
			Name = "WeaponInfo",
			Position = function()
				return position()
			end,
			AnchorPoint = function()
				if position() == UDim2.new(1, -10, 1, -10) then
					return Vector2.new(1, 1)
				else
					return Vector2.new(0.5, 0.5)
				end
			end,
			Size = px.offset(80, 40),
			BackgroundColor3 = theme.background.elevated,
			BackgroundTransparency = 1,
			create "TextLabel" {
				Name = "CurrentAmmo",
				Size = UDim2.fromScale(1, 1),
				Text = function()
					local current = currentAmmo() or 0
					local total = totalAmmo() or 0
					local titleText = if isReloading() then "Reloading..." else currentWeaponName()
					local text =
						`<b><font size="18">{titleText}</font></b><br/><font size="20"><b>{current}</b></font> <font size="20">/</font> <font size="15">{total}</font>`
					if isReloading() then
						return `<font color="#FF5555">{text}</font>`
					end
					return text
				end,
				TextColor3 = theme.colors.neutral,
				create "UIStroke" {
					Color = theme.stroke.color,
					Thickness = theme.stroke.thickness,
				},
				TextXAlignment = function()
					if firstPerson() then
						return Enum.TextXAlignment.Right
					else
						return Enum.TextXAlignment.Left
					end
				end,
				FontFace = theme.fonts.sans,
				BackgroundTransparency = 1,
				RichText = true,
			},
			create "UICorner" {
				CornerRadius = theme.radii.rounded,
			},
		},
	}
end

return App
