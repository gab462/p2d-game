package main

Collision_Event :: struct {
	data: Collision,
	a, b: int,
}

Jump_Event :: struct {
	entity: int,
}

Event :: union {
	Collision_Event,
	Jump_Event,
}
