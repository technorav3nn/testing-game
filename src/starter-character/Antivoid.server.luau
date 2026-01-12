--!nonstrict
-- Why does this script exist?
-- Because theres a bug in my gun system that wouldn't refresh the cursor
-- when the character falls out of the world and respawns.
-- This is a temporary fix until I can find a better solution

local character = (script.Parent :: any) :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local isFalling = false

local function onFreeFalling(Active)
	isFalling = Active
	while isFalling do
		if humanoidRootPart.Position.Y <= -50 then
			humanoidRootPart.Anchored = true
			task.wait(1)
			local success, err: string? = pcall(function()
				for _, v in ipairs(character:GetDescendants()) do
					if v:IsA("BasePart") then
						(v :: any).Velocity = Vector3.new(0, 0, 0)
					end
				end
				character:PivotTo(CFrame.new(0, 0, 0))
			end)
			if success then
				humanoidRootPart.Anchored = false
			else
				warn(err)
			end
		end
		task.wait(0.1)
	end
end

humanoid.FreeFalling:Connect(onFreeFalling)
