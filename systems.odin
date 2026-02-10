package main

import "core:math/linalg"
import rl "vendor:raylib"

movement_system :: proc(e: ^#soa[dynamic]Entity, dt: f32) {
	traits: Traits = {.Physical, .Dynamic}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].traits >= traits) {continue}
		e[i].position += e[i].velocity * dt
	}
}

collision_system :: proc(e: ^#soa[dynamic]Entity, events: ^[dynamic]Event) {
	for i := 0; i < len(e) - 1; i += 1 {
		if !(.Physical in e[i].traits) {continue}

		for j := i + 1; j < len(e); j += 1 {
			if !(.Physical in e[j].traits) {continue}

			collider, collided: int
			if e[i].traits >= {.Dynamic, .Collision} {
				collider, collided = i, j
			} else if e[j].traits >= {.Dynamic, .Collision} {
				collider, collided = j, i
			} else {
				// both objects are static and/or do not collide
				continue
			}

			if e[collider].collides_with & e[collided].traits == (Traits{}) {
				continue
			}

			collision, hit := collide(
				e[collider].position,
				e[collided].position,
				e[collider].shape,
				e[collided].shape,
			)

			if hit {
				append(events, Collision_Event{data = collision, a = collider, b = collided})
			}
		}
	}
}

event_processing_task :: proc(e: ^#soa[dynamic]Entity, events: ^[dynamic]Event, player: int) {
	for event in events {
		switch ev in event {
		case Collision_Event:
			e[ev.a].position += ev.data.mtv

			if ev.data.mtv.y > 0.0 && e[ev.a].velocity.y < 0.0 {
				// hitting ground, cancel gravity
				e[ev.a].velocity.y = 0.0
			}

			if ev.a == player && .Damage in e[ev.b].traits {
				// respawn player
				e[player].position = {0.0, 10.0, 0.0}
			}
		}
	}

	clear(events)
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity) {
	traits: Traits = {.Physical}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].traits >= traits) {continue}

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
	traits: Traits = {.Controlled}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].traits >= traits) {continue}

		if .Dynamic in e[i].traits {
			intent := e[i].controls.move_intent

			// velocity instead of position due to non-controlled objects with inertia
			e[i].velocity.xz = intent.direction * intent.max_speed
		}

		if .Rotation in e[i].traits {
			intent := e[i].controls.rotate_intent

			e[i].rotation += intent.delta * intent.sensitivity
		}
	}
}

input_task :: proc(world: ^World, player: int) {
	e := &world.entities

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
			e[player].rotation.x,
		)
		e[player].controls.move_intent.direction = rotated.xy
	} else {
		e[player].controls.move_intent.direction = {}
	}

	// Rotation
	e[player].controls.rotate_intent.delta = rl.GetMouseDelta()
}

camera_control_task :: proc(world: ^World, player: int) {
	cam := &world.camera

	e := &world.entities

	shape := e[player].shape.(Cylinder)

	head := e[player].position
	head.y += shape.height - shape.radius

	cam.target += head - cam.position
	cam.position = head

	rotate := e[player].controls.rotate_intent.delta * e[player].controls.rotate_intent.sensitivity
	rl.CameraYaw(cam, -rotate.x, false)
	rl.CameraPitch(cam, -rotate.y, true, false, false)
}

gravity_system :: proc(e: ^#soa[dynamic]Entity, acceleration: f32, dt: f32) {
	traits: Traits = {.Dynamic}

	for i := 0; i < len(e); i += 1 {
		if !(e[i].traits >= traits) {continue}

		e[i].velocity.y -= acceleration * dt
	}
}
