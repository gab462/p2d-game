package main

import "core:math"

Collision :: struct {
	mtv: [3]f32,
}

cylinders_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: Cylinder) -> (Collision, bool) {
	// horizontal test

	radius_sum := shape_a.radius + shape_b.radius

	horizontal_distance_vector := pos_a.xz - pos_b.xz
	square_horizontal_distance := square_magnitude(horizontal_distance_vector)

	if square_horizontal_distance > radius_sum * radius_sum {return {}, false}

	// vertical test

	half_height_sum := shape_a.height / 2.0 + shape_b.height / 2.0

	a_center_y := pos_a.y + shape_a.height / 2.0
	b_center_y := pos_b.y + shape_b.height / 2.0
	vertical_distance := a_center_y - b_center_y
	vertical_depth := half_height_sum - abs(vertical_distance)

	if vertical_depth < 0.0 {return {}, false}

	// collision

	horizontal_distance := math.sqrt(square_horizontal_distance)
	horizontal_depth := radius_sum - horizontal_distance

	if horizontal_depth < vertical_depth {
		return {
			mtv = vec3_from_xz(
				horizontal_depth * (horizontal_distance_vector / horizontal_distance),
			),
		},
		true
	} else {
		return {mtv = [3]f32{0.0, vertical_depth * math.sign(vertical_distance), 0.0}}, true
	}
}

aabb_collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: AABB) -> (Collision, bool) {
	a_half_size := shape_a.size / 2.0
	b_half_size := shape_b.size / 2.0

	a_center := pos_a
	a_center.y += a_half_size.y

	b_center := pos_b
	b_center.y += b_half_size.y

	half_size_sum := a_half_size + b_half_size

	distance := a_center - b_center
	depth := half_size_sum - [3]f32{abs(distance.x), abs(distance.y), abs(distance.z)}

	if depth.x < 0.0 {return {}, false}
	if depth.y < 0.0 {return {}, false}
	if depth.z < 0.0 {return {}, false}

	if depth.x < depth.y && depth.x < depth.z {
		return {mtv = [3]f32{depth.x * math.sign(distance.x), 0.0, 0.0}}, true
	} else if depth.y < depth.z {
		return {mtv = [3]f32{0.0, depth.y * math.sign(distance.y), 0.0}}, true
	} else {
		return {mtv = [3]f32{0.0, 0.0, depth.z * math.sign(distance.z)}}, true
	}
}

aabb_cylinder_collide :: proc(
	pos_aabb, pos_cylinder: [3]f32,
	shape_aabb: AABB,
	shape_cylinder: Cylinder,
) -> (
	Collision,
	bool,
) {
	aabb_half_size := shape_aabb.size / 2.0

	cylinder_half_size := [3]f32 {
		shape_cylinder.radius,
		shape_cylinder.height / 2.0,
		shape_cylinder.radius,
	}

	aabb_center := pos_aabb
	aabb_center.y += aabb_half_size.y

	cylinder_center := pos_cylinder
	cylinder_center.y += cylinder_half_size.y

	half_size_sum := aabb_half_size + cylinder_half_size

	distance := aabb_center - cylinder_center
	depth := half_size_sum - [3]f32{abs(distance.x), abs(distance.y), abs(distance.z)}

	// aabb tests

	if depth.x < 0.0 {return {}, false}
	if depth.y < 0.0 {return {}, false}
	if depth.z < 0.0 {return {}, false}

	// edge radius test

	closest_aabb := [2]f32 {
		clamp(
			pos_cylinder.x,
			pos_aabb.x - shape_aabb.size.x / 2.0,
			pos_aabb.x + shape_aabb.size.x / 2.0,
		),
		clamp(
			pos_cylinder.z,
			pos_aabb.z - shape_aabb.size.z / 2.0,
			pos_aabb.z + shape_aabb.size.z / 2.0,
		),
	}

	horizontal_distance_vector := closest_aabb - pos_cylinder.xz
	square_horizontal_distance := square_magnitude(horizontal_distance_vector)

	if square_horizontal_distance >
	   shape_cylinder.radius * shape_cylinder.radius {return {}, false}

	// collision

	if square_horizontal_distance == 0 {
		// cylinder inside aabb, solve using aabb logic

		if depth.x < depth.y && depth.x < depth.z {
			return {mtv = [3]f32{depth.x * math.sign(distance.x), 0.0, 0.0}}, true
		} else if depth.y < depth.z {
			return {mtv = [3]f32{0.0, depth.y * math.sign(distance.y), 0.0}}, true
		} else {
			return {mtv = [3]f32{0.0, 0.0, depth.z * math.sign(distance.z)}}, true
		}
	}

	horizontal_distance := math.sqrt(square_horizontal_distance)
	horizontal_depth := shape_cylinder.radius - horizontal_distance

	if horizontal_depth < depth.y {
		return {
			mtv = vec3_from_xz(
				horizontal_depth * (horizontal_distance_vector / horizontal_distance),
			),
		},
		true
	} else {
		return {mtv = [3]f32{0.0, depth.y * math.sign(distance.y), 0.0}}, true
	}
}

cylinder_aabb_collide :: proc(
	pos_cylinder, pos_aabb: [3]f32,
	shape_cylinder: Cylinder,
	shape_aabb: AABB,
) -> (
	Collision,
	bool,
) {
	coll, hit := aabb_cylinder_collide(pos_aabb, pos_cylinder, shape_aabb, shape_cylinder)
	return {-coll.mtv}, hit
}

collide :: proc(pos_a, pos_b: [3]f32, shape_a, shape_b: Shape) -> (Collision, bool) {
	switch a in shape_a {
	case Cylinder:
		switch b in shape_b {
		case Cylinder:
			return cylinders_collide(pos_a, pos_b, a, b)
		case AABB:
			return cylinder_aabb_collide(pos_a, pos_b, a, b)
		}
	case AABB:
		switch b in shape_b {
		case Cylinder:
			return aabb_cylinder_collide(pos_a, pos_b, a, b)
		case AABB:
			return aabb_collide(pos_a, pos_b, a, b)
		}
	}
	return {}, false
}
