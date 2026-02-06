package main

import "core:math"

square_distance_3d :: proc(a, b: [3]f32) -> f32 {
	d := a - b
	return d.x * d.x + d.y * d.y + d.z * d.z
}

square_distance_2d :: proc(a, b: [2]f32) -> f32 {
	d := a - b
	return d.x * d.x + d.y * d.y
}

square_distance :: proc {
	square_distance_2d,
	square_distance_3d,
}

overlap_1d :: proc(a1, a2, b1, b2: f32) -> bool {
	return a2 >= b1 && b2 >= a1
}

aabb_min_max :: proc(pos: [3]f32, size: [3]f32) -> ([3]f32, [3]f32) {
	center := pos + [3]f32{0.0, size.y / 2.0, 0.0}
	return center - size / 2.0, center + size / 2.0
}

capsule_hemispheres :: proc(pos: [3]f32, shape: Capsule) -> (f32, f32) {
	return pos.y + shape.height - shape.radius, pos.y + shape.radius
}

vector_rotate :: proc(target: [2]f32, amount: f32, center: [2]f32 = {}) -> [2]f32 {
	res := target - center
	return(
		[2]f32 {
			res.x * math.cos(amount) - res.y * math.sin(amount),
			res.x * math.sin(amount) + res.y * math.cos(amount),
		} +
		center \
	)
}
