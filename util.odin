package main

capsule_hemispheres :: proc(pos: [3]f32, shape: Capsule) -> (f32, f32) {
	return pos.y + shape.height - shape.radius, pos.y + shape.radius
}
