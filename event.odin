package main

Collision_Event :: struct {
	data: Collision,
	a, b: int,
}

Jump_Event :: struct {
	entity: int,
}

Particle_Event :: struct {
	origin:           [3]f32,
	particle_count:   int,
	initial_velocity: [3]f32,
	max_variation:    f32,
	lifetime:         f32,
}

Projectile_Event :: struct {
	origin:        [3]f32,
	velocity:      [3]f32,
	collides_with: Traits,
}

Event :: union {
	Collision_Event,
	Jump_Event,
	Particle_Event,
	Projectile_Event,
}
