package main

Trait :: enum {
	Physical, // Position, Shape
	Dynamic, // velocity, gravity
	Rotation,
	Collision,
	Controlled,
	Damage,
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

Move_Intent :: struct {
	max_speed: f32,
	direction: [2]f32,
}

Rotate_Intent :: struct {
	sensitivity: f32,
	delta:       [2]f32,
}

Controls :: struct {
	move_intent:   Move_Intent,
	rotate_intent: Rotate_Intent,
}
