package main

Trait :: enum {
	Inactive,
	Physical, // Position, Shape
	Dynamic, // Velocity, Gravity
	Rotation,
	Collision,
	Controlled,
	Damage,
	Particle,
}

Traits :: bit_set[Trait]

Cylinder :: struct {
	radius: f32,
	height: f32,
}

AABB :: struct {
	size: [3]f32,
}

Shape :: union #no_nil {
	Cylinder,
	AABB,
}

Jumps :: struct {
	count:     int,
	remaining: int,
	force:     f32,
}

Particle_State :: struct {
	lifetime: f32,
}
