package main

Collision_Event :: struct {
	data: Collision,
	a, b: int,
}

Event :: union {
	Collision_Event,
}
