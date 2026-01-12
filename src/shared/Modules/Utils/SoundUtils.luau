local SoundUtils = {}
SoundUtils.CommonSounds = {
	Error = "rbxassetid://3779045779",
}

function SoundUtils:PlaySound(config: {
	source: Instance,
	id: string?,
	sound: Sound?,
	volume: number?,
	looped: boolean?,
})
	local sound: Sound
	if config.sound then
		sound = config.sound:Clone()
		sound.Parent = config.source
	else
		if not config.id then
			error("SoundUtils:PlaySound requires either a sound or an id.")
		end
		sound = Instance.new("Sound")
		sound.SoundId = config.id
		sound.Volume = config.volume or 1
		sound.Parent = config.source
		sound.Looped = config.looped or false
	end

	sound:Play()
	if not sound.Looped then
		local conn
		conn = sound.Ended:Connect(function()
			task.wait(0.5)
			sound:Destroy()
			if conn then
				conn:Disconnect()
			end
		end)
	end
	return sound
end

return SoundUtils
