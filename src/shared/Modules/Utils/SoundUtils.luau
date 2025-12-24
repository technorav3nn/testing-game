local SoundUtils = {}

type PlaySoundConfig = {
	SoundToPlay: Sound,
	Parent: Instance,
	Volume: number?,
	Pitch: number?,
	Looped: boolean?,
	OnEnded: ((sound: Sound) -> ())?,
}

function SoundUtils:PlaySound(config: PlaySoundConfig)
	local soundClone = config.SoundToPlay:Clone()
	soundClone.Parent = config.Parent
	soundClone.Volume = config.Volume or 1
	soundClone.PlaybackSpeed = config.Pitch or 1
	soundClone.Looped = config.Looped or false

	soundClone:Play()
	soundClone.Ended:Connect(function()
		if config.OnEnded then
			config.OnEnded(soundClone)
		end
		soundClone:Destroy()
	end)
end

return SoundUtils
