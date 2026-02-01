package main

Component :: enum {
	Position,
	Velocity,
	Shape,
	Collision_Mask,
}

Mask :: bit_set[Component]

Position :: [3]f32

Velocity :: [3]f32

Capsule :: struct {
	radius: f32,
	height: f32,
}

AABB :: struct {
	size: [3]f32,
}

Shape :: union {
	Capsule,
	AABB,
}

Collision_Mask :: Mask
