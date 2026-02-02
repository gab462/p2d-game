package main

square_distance_3d :: proc(a: [3]f32, b: [3]f32) -> f32 {
	d := a - b
	return d.x * d.x + d.y * d.y + d.z * d.z
}

square_distance_2d :: proc(a: [2]f32, b: [2]f32) -> f32 {
	d := a - b
	return d.x * d.x + d.y * d.y
}

square_distance :: proc {
	square_distance_2d,
	square_distance_3d
}

capsules_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: Capsule) -> bool {
	// rough horizontal test

	radius_sum := shape_a.radius + shape_b.radius

	if square_distance(pos_a.xz, pos_b.xz) > radius_sum * radius_sum { return false }

	// rough vertical test

	half_height_sum := shape_a.height / 2.0 + shape_b.height / 2.0

	a_center_y := pos_a.y + shape_a.height / 2.0
	b_center_y := pos_b.y + shape_b.height / 2.0

	if abs(a_center_y - b_center_y) > half_height_sum { return false }

	// calculate closest y points and test distance

	a_head := pos_a.y + shape_a.height - shape_a.radius
	a_toe := pos_a.y + shape_a.radius
	b_head := pos_b.y + shape_b.height - shape_b.radius
	b_toe := pos_b.y + shape_b.radius

	a_closest_y := clamp(b_toe, a_toe, a_head)
	b_closest_y := clamp(a_toe, b_toe, b_head)

	a_closest := [3]f32{ pos_a.x, a_closest_y, pos_a.z }
	b_closest := [3]f32{ pos_b.x, b_closest_y, pos_b.z }

	return square_distance(a_closest, b_closest) <= radius_sum * radius_sum
}

overlap_1d :: proc(a1, a2, b1, b2: f32) -> bool {
	return a2 >= b1 && b2 >= a1
}

aabb_min_max :: proc(pos: [3]f32, size: [3]f32) -> ([3]f32, [3]f32) {
	center := pos + [3]f32{ 0.0, size.y / 2.0, 0.0 }
	return center - size / 2.0, center + size / 2.0
}

aabb_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: AABB) -> bool {
	a_min, a_max := aabb_min_max(pos_a, shape_a.size)
	b_min, b_max := aabb_min_max(pos_b, shape_b.size)

	if !overlap_1d(a_min.x, a_max.x, b_min.x, b_max.x) { return false }
	if !overlap_1d(a_min.z, a_max.z, b_min.z, b_max.z) { return false }
	if !overlap_1d(a_min.y, a_max.y, b_min.y, b_max.y) { return false }

	return true
}

aabb_capsule_collide :: proc(pos_aabb, pos_capsule: [3]f32, shape_aabb: AABB, shape_capsule: Capsule) -> bool {
	aabb_min, aabb_max := aabb_min_max(pos_aabb, shape_aabb.size)

	// rough aabb tests

	if pos_capsule.x + shape_capsule.radius < aabb_min.x { return false }
	if pos_capsule.x - shape_capsule.radius > aabb_max.x { return false }
	if pos_capsule.z + shape_capsule.radius < aabb_min.z { return false }
	if pos_capsule.z - shape_capsule.radius > aabb_max.z { return false }
	if pos_capsule.y + shape_capsule.height < aabb_min.y { return false }
	if pos_capsule.y > aabb_max.y { return false }

	// rough edge radius test

	closest_aabb: [3]f32

	closest_aabb.x = clamp(pos_capsule.x, aabb_min.x, aabb_max.x)
	closest_aabb.z = clamp(pos_capsule.z, aabb_min.z, aabb_max.z)

	if square_distance(pos_capsule.xz, closest_aabb.xz) > shape_capsule.radius * shape_capsule.radius { return false }

	// find closest point on capsule and aabb and test distance

	capsule_head := pos_capsule.y + shape_capsule.height - shape_capsule.radius
	capsule_toe := pos_capsule.y + shape_capsule.radius

	closest_aabb.y = clamp(capsule_toe, aabb_min.y, aabb_max.y)
	closest_capsule_y := clamp(closest_aabb.y, capsule_toe, capsule_head)

	closest_capsule := [3]f32{ pos_capsule.x, closest_capsule_y, pos_capsule.z }

	return square_distance(closest_capsule, closest_aabb) <= shape_capsule.radius * shape_capsule.radius
}
