package main

import "core:math/linalg"
import rl "vendor:raylib"

movement_system :: proc(e: ^#soa[dynamic]Entity, dt: f32) {
	mask: Mask = {.Position, .Velocity}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}
		e[i].position += e[i].velocity * dt
	}
}

collision_system :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = {.Position, .Shape, .Collision_Mask}

	for i := 0; i < len(e) - 1; i += 1 {
		if !(e[i].mask >= mask) {continue}

		for j := i + 1; j < len(e); j += 1 {
			if !(e[j].mask >= mask) {continue}
			if e[i].collision_mask & e[j].mask == (Mask{}) {continue}

			collision := collide(e[i].position, e[j].position, e[i].shape, e[j].shape)
			// TODO: save collision
		}
	}
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = {.Position, .Shape}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		switch s in e[i].shape {
		case Capsule:
			pos := e[i].position
			head, toe := capsule_hemispheres(pos, s)

			rl.DrawCapsuleWires(
				[3]f32{pos.x, toe, pos.z},
				[3]f32{pos.x, head, pos.z},
				s.radius,
				8,
				8,
				rl.GREEN,
			)
		case AABB:
			rl.DrawCubeWiresV(e[i].position + [3]f32{0.0, s.size.y / 2.0, 0.0}, s.size, rl.GREEN)
		}
	}
}

input_task :: proc(world: ^World) {
}

movement_control_system :: proc(e: ^#soa[dynamic]Entity) {
	mask := Mask{.Velocity, .Movement_Control}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		intent := e[i].move_intent
		e[i].velocity.xz = intent.direction * intent.max_speed
		// TODO: zero value to consume?
	}
}

camera_control_task :: proc(world: ^World, dt: f32) {
	cam := &world.camera

	e := &world.entities
	p1 := 0 // player is always entity 0

	forward := rl.IsKeyDown(rl.KeyboardKey.W)
	backward := rl.IsKeyDown(rl.KeyboardKey.S)
	right := rl.IsKeyDown(rl.KeyboardKey.D)
	left := rl.IsKeyDown(rl.KeyboardKey.A)

	direction := [2]f32{f32(int(forward)) - f32(int(backward)), f32(int(right)) - f32(int(left))}

	if (direction.y != 0.0 || direction.x != 0.0) {
		direction = linalg.normalize(direction)
	}

	rotate := rl.GetMouseDelta()

	rotation := e[p1].rotate_intent
	movement := e[p1].move_intent

	rl.UpdateCameraPro(
		cam,
		[3]f32{direction.x, direction.y, 0.0} * movement.max_speed * dt,
		{rotate.x, rotate.y, 0.0} * rotation.sensitivity,
		0.0,
	)

	if (cam.position.xz != e[p1].position.xz) { 	// FIXME
		e[p1].move_intent.direction =
			(cam.position.xz - e[p1].position.xz) / movement.max_speed / dt
	}
	e[p1].rotate_intent.delta = rotate.x // FIXME
}
