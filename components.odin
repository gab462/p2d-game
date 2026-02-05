package main

Component :: enum {
	Position,
	Velocity,
	Shape,
	Collision_Mask,
	Movement_Control,
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

Shape :: union #no_nil {
	Capsule,
	AABB,
}

Collision_Mask :: Mask

Move_Intent :: struct {
	max_speed: f32,
	direction: [2]f32,
}

Look_Intent :: struct {
	delta: [2]f32,
}
