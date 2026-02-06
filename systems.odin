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

movement_control_system :: proc(e: ^#soa[dynamic]Entity) {
	mask := Mask{.Velocity, .Controlled}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		intent := e[i].controlled.move_intent
		e[i].velocity.xz = intent.direction * intent.max_speed
		e[i].controlled.move_intent.direction = {} // consume
	}
}

rotation_control_system :: proc(e: ^#soa[dynamic]Entity) {
	mask := Mask{.Rotation, .Controlled}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		intent := e[i].controlled.rotate_intent
		e[i].rotation += intent.delta * intent.sensitivity
		e[i].controlled.rotate_intent.delta = {} // consume
	}
}

input_task :: proc(world: ^World) {
	e := &world.entities
	p1 := 0 // player is always entity 0

	// Movement
	forward := rl.IsKeyDown(rl.KeyboardKey.W)
	backward := rl.IsKeyDown(rl.KeyboardKey.S)
	right := rl.IsKeyDown(rl.KeyboardKey.D)
	left := rl.IsKeyDown(rl.KeyboardKey.A)

	direction := [2]f32{f32(int(forward)) - f32(int(backward)), f32(int(right)) - f32(int(left))}

	if (direction.y != 0.0 || direction.x != 0.0) {
		direction = linalg.normalize(direction)

		// rotate to camera angle
		e[p1].controlled.move_intent.direction = vector_rotate(direction, e[p1].rotation.x)
	}

	// Rotation
	e[p1].controlled.rotate_intent.delta = rl.GetMouseDelta()
}

camera_control_task :: proc(world: ^World, dt: f32) {
	cam := &world.camera

	e := &world.entities
	p1 := 0 // player is always entity 0

	move := e[p1].controlled.move_intent.direction * e[p1].controlled.move_intent.max_speed * dt
	velocity := e[p1].velocity * dt

	cam.position += [3]f32{move.x, velocity.y, move.y}
	cam.target += [3]f32{move.x, velocity.y, move.y}

	rotate := e[p1].controlled.rotate_intent.delta * e[p1].controlled.rotate_intent.sensitivity
	rl.CameraYaw(cam, -rotate.x, false)
	rl.CameraPitch(cam, -rotate.y, true, false, false)
}
