export type Service<T> = {
	OnStart: () -> () | (self: T) -> (),
}

return {}
