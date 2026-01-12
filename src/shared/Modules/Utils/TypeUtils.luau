export type function keyof(ty)
	if not ty:is("table") then
		error("Can only call keyof on tables.")
	end

	local union = nil

	for property in ty:properties() do
		union = if union then types.unionof(union, property) else property
	end

	return if union then union else types.singleton(nil)
end

export type function getkey(ty: type, key)
	if not ty:is("table") then
		error("Can only call getkey on tables.")
	end

	local property = ty:readproperty(key)
	if not property then
		error("Key '" .. tostring(key) .. "' does not exist on type.")
	end

	return property
end

return "!! THIS MODULE ONY EXPORTS TYPES !!"
