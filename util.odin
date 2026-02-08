package main

square_magnitude_3d :: proc(d: [3]f32) -> f32 {
	return d.x * d.x + d.y * d.y + d.z * d.z
}

square_magnitude_2d :: proc(d: [2]f32) -> f32 {
	return d.x * d.x + d.y * d.y
}

square_magnitude :: proc {
	square_magnitude_2d,
	square_magnitude_3d,
}

vec3_from_xz :: proc(v: [2]f32) -> [3]f32 {
	return { v.x, 0.0, v.y }
}
