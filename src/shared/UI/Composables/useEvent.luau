local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.Vide)

local function useEvent<T, C>(event: RBXScriptSignal, callback: (C) -> ...any)
	local connection = event:Connect(callback)
	vide.cleanup(connection)
	return connection
end

return useEvent :: <T, C>(event: RBXScriptSignal, callback: (C) -> ...any) -> RBXScriptConnection
