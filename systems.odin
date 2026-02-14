package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

movement_system :: proc(e: ^#soa[dynamic]Entity, dt: f32) {
	traits: Traits = {.Physical, .Dynamic}

	for i := 0; i < len(e); i += 1 {
		if .Inactive in e[i].traits {continue}
		if !(e[i].traits >= traits) {continue}
		e[i].position += e[i].velocity * dt
	}
}

collision_system :: proc(e: ^#soa[dynamic]Entity, events: ^[dynamic]Event) {
	for i := 0; i < len(e) - 1; i += 1 {
		if .Inactive in e[i].traits {continue}
		if .Physical not_in e[i].traits {continue}

		for j := i + 1; j < len(e); j += 1 {
			if .Inactive in e[j].traits {continue}
			if .Physical not_in e[j].traits {continue}

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
				e[ev.a].jumps.remaining = e[ev.a].jumps.count
			}

			if ev.a == player && .Damage in e[ev.b].traits {
				// respawn player
				e[player].position = {0.0, 10.0, 0.0}
			}
		case Jump_Event:
			jump := e[ev.entity].jumps
			if jump.remaining == 0 {
				// tried to jump with no jumps left
				continue
			}

			if jump.remaining > 0 {
				e[ev.entity].jumps.remaining -= 1
			}

			e[ev.entity].velocity.y = jump.force
		}
	}

	clear(events)
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity) {
	traits: Traits = {.Physical}

	for i := 0; i < len(e); i += 1 {
		if .Inactive in e[i].traits {continue}
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

debug_stats_task :: proc(e: ^#soa[dynamic]Entity, player: int) {
	x: i32 = 5
	y: i32 = 0
	h: i32 = 20

	rl.DrawFPS(x, y)
	y += h

	rl.DrawText(fmt.ctprintf("Max Entities: %v", len(e)), x, y, 20, rl.LIME)
	y += h

	pos := e[player].position
	coords := [3]int{int(pos.x), int(pos.y), int(pos.z)}
	rl.DrawText(fmt.ctprintf("Coords: %v", coords), x, y, 20, rl.LIME)
	y += h

	rl.DrawText(fmt.ctprintf("Rotation: %v", e[player].rotation), x, y, 20, rl.LIME)
	y += h
}

input_task :: proc(world: ^World, events: ^[dynamic]Event, player: int) {
	e := &world.entities

	// Movement
	forward := rl.IsKeyDown(rl.KeyboardKey.W)
	backward := rl.IsKeyDown(rl.KeyboardKey.S)
	right := rl.IsKeyDown(rl.KeyboardKey.D)
	left := rl.IsKeyDown(rl.KeyboardKey.A)

	direction := [3]f32 {
		f32(int(left)) - f32(int(right)),
		0.0,
		f32(int(forward)) - f32(int(backward)),
	}

	if (direction.x != 0.0 || direction.z != 0.0) {
		direction = linalg.normalize(direction)

		// rotate to camera angle
		rotated := rl.Vector3RotateByAxisAngle(direction, {0.0, 1.0, 0.0}, e[player].rotation)
		e[player].velocity.xz = (rotated * e[player].max_speed).xz
	} else {
		e[player].velocity.xz = [2]f32{}
	}

	// Rotation
	e[player].rotation -= rl.GetMouseDelta().x * world.mouse_sensitivity

	// Jumping
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		append(events, Jump_Event{entity = player})
	}
}

camera_control_task :: proc(world: ^World, player: int) {
	cam := &world.camera

	e := &world.entities

	shape := e[player].shape.(Cylinder)

	head := e[player].position
	head.y += shape.height - shape.radius

	cam.target += head - cam.position
	cam.position = head

	rotate := rl.GetMouseDelta() * -1 * world.mouse_sensitivity
	rl.CameraYaw(cam, rotate.x, false)
	rl.CameraPitch(cam, rotate.y, true, false, false)
}

gravity_system :: proc(e: ^#soa[dynamic]Entity, acceleration: f32, dt: f32) {
	traits: Traits = {.Dynamic}

	for i := 0; i < len(e); i += 1 {
		if .Inactive in e[i].traits {continue}
		if !(e[i].traits >= traits) {continue}

		e[i].velocity.y -= acceleration * dt
	}
}
