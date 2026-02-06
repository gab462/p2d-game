package main

cylinders_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: Cylinder) -> bool {
	// horizontal test

	radius_sum := shape_a.radius + shape_b.radius

	if square_distance(pos_a.xz, pos_b.xz) > radius_sum * radius_sum {return false}

	// vertical test

	half_height_sum := shape_a.height / 2.0 + shape_b.height / 2.0

	a_center_y := pos_a.y + shape_a.height / 2.0
	b_center_y := pos_b.y + shape_b.height / 2.0

	if abs(a_center_y - b_center_y) > half_height_sum {return false}

	// TODO: calculate normal and depth
	return true
}

aabb_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: AABB) -> bool {
	a_min, a_max := aabb_min_max(pos_a, shape_a.size)
	b_min, b_max := aabb_min_max(pos_b, shape_b.size)

	if !overlap_1d(a_min.x, a_max.x, b_min.x, b_max.x) {return false}
	if !overlap_1d(a_min.z, a_max.z, b_min.z, b_max.z) {return false}
	if !overlap_1d(a_min.y, a_max.y, b_min.y, b_max.y) {return false}

	// TODO: calculate normal and depth
	return true
}

aabb_cylinder_collide :: proc(
	pos_aabb, pos_cylinder: [3]f32,
	shape_aabb: AABB,
	shape_cylinder: Cylinder,
) -> bool {
	aabb_min, aabb_max := aabb_min_max(pos_aabb, shape_aabb.size)

	// aabb tests

	if pos_cylinder.x + shape_cylinder.radius < aabb_min.x {return false}
	if pos_cylinder.x - shape_cylinder.radius > aabb_max.x {return false}
	if pos_cylinder.z + shape_cylinder.radius < aabb_min.z {return false}
	if pos_cylinder.z - shape_cylinder.radius > aabb_max.z {return false}
	if pos_cylinder.y + shape_cylinder.height < aabb_min.y {return false}
	if pos_cylinder.y > aabb_max.y {return false}

	// edge radius test

	closest_aabb: [3]f32

	closest_aabb.x = clamp(pos_cylinder.x, aabb_min.x, aabb_max.x)
	closest_aabb.z = clamp(pos_cylinder.z, aabb_min.z, aabb_max.z)

	if square_distance(pos_cylinder.xz, closest_aabb.xz) >
	   shape_cylinder.radius * shape_cylinder.radius {return false}

	// TODO: calculate normal and depth
	return true
}

collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: Shape) -> bool {
	switch a in shape_a {
	case Cylinder:
		switch b in shape_b {
		case Cylinder:
			return cylinders_collide(pos_a, pos_b, a, b)
		case AABB:
			return aabb_cylinder_collide(pos_b, pos_a, b, a)
		}
	case AABB:
		switch b in shape_b {
		case Cylinder:
			return aabb_cylinder_collide(pos_a, pos_b, a, b)
		case AABB:
			return aabb_collide(pos_a, pos_b, a, b)
		}
	}
	return false
}
