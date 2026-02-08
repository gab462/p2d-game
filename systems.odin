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
	mask: Mask = {.Position, .Velocity, .Shape, .Collision_Mask}

	for i := 0; i < len(e) - 1; i += 1 {
		if !(e[i].mask >= mask) {continue}

		for j := i + 1; j < len(e); j += 1 {
			if !(e[j].mask >= {.Position, .Shape}) {continue}
			if e[i].collision_mask & e[j].mask == (Mask{}) {continue}

			// TODO: save collision
			collision, hit := collide(e[i].position, e[j].position, e[i].shape, e[j].shape)

			if hit {
				e[i].position += collision.mtv

				if collision.mtv.y > 0.0 && e[i].velocity.y < 0.0 {
					// hitting ground, cancel gravity
					e[i].velocity.y = 0.0
				}
			}
		}
	}
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = {.Position, .Shape}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		switch s in e[i].shape {
		case Cylinder:
			pos := e[i].position

			rl.DrawCylinderWires(pos, s.radius, s.radius, s.height, 8, rl.GREEN)
		case AABB:
			rl.DrawCubeWiresV(e[i].position + [3]f32{0.0, s.size.y / 2.0, 0.0}, s.size, rl.GREEN)
		}
	}
}

control_system :: proc(e: ^#soa[dynamic]Entity) {
	mask := Mask{.Controlled}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		if .Velocity in e[i].mask {
			intent := e[i].controlled.move_intent

			// velocity instead of position due to non-controlled objects with inertia
			e[i].velocity.xz = intent.direction * intent.max_speed
		}

		if .Rotation in e[i].mask {
			intent := e[i].controlled.rotate_intent

			e[i].rotation += intent.delta * intent.sensitivity
		}
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
		rotated := rl.Vector3RotateByAxisAngle(
			{direction.x, direction.y, 0.0},
			{0.0, 0.0, 1.0},
			e[p1].rotation.x,
		)
		e[p1].controlled.move_intent.direction = rotated.xy
	} else {
		e[p1].controlled.move_intent.direction = {}
	}

	// Rotation
	e[p1].controlled.rotate_intent.delta = rl.GetMouseDelta()
}

camera_control_task :: proc(world: ^World, dt: f32) {
	cam := &world.camera

	e := &world.entities
	p1 := 0 // player is always entity 0

	shape := e[p1].shape.(Cylinder)

	head := e[p1].position
	head.y += shape.height - shape.radius

	cam.target += head - cam.position
	cam.position = head

	rotate := e[p1].controlled.rotate_intent.delta * e[p1].controlled.rotate_intent.sensitivity
	rl.CameraYaw(cam, -rotate.x, false)
	rl.CameraPitch(cam, -rotate.y, true, false, false)
}

gravity_system :: proc(e: ^#soa[dynamic]Entity, acceleration: f32, dt: f32) {
	mask := Mask{.Velocity} // TODO: flag for entities affected by gravity

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) {continue}

		e[i].velocity.y -= acceleration * dt
	}
}
