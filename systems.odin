package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

System_Proc_Type :: proc(e: ^#soa[dynamic]Entity, w: ^World, idx: int)

run_system :: proc(w: ^World, func: System_Proc_Type, traits: Traits) {
	for i := 0; i < len(w.entities); i += 1 {
		if .Inactive in w.entities[i].traits {continue}
		if !(w.entities[i].traits >= traits) {continue}

		func(&w.entities, w, i)
	}
}

movement_system :: proc(e: ^#soa[dynamic]Entity, world: ^World, i: int) {
	e[i].position += e[i].velocity * world.dt
}

collision_system :: proc(e: ^#soa[dynamic]Entity, world: ^World, i: int) {
	for j := i + 1; j < len(e); j += 1 {
		if .Inactive in e[j].traits {continue}
		if !(e[j].traits >= {.Physical, .Collision}) {continue}

		collider, collided: int
		if .Dynamic in e[i].traits {
			collider, collided = i, j
		} else if .Dynamic in e[j].traits {
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
			append(&world.events, Collision_Event{data = collision, a = collider, b = collided})
		}
	}
}

event_processing_task :: proc(e: ^#soa[dynamic]Entity, world: ^World) {
	for event in world.events {
		switch ev in event {
		case Collision_Event:
			e[ev.a].position += ev.data.mtv

			if ev.data.mtv.y > 0.0 && e[ev.a].velocity.y < 0.0 {
				// hitting ground, cancel gravity
				e[ev.a].velocity.y = 0.0
				e[ev.a].jumps.remaining = e[ev.a].jumps.count
			}

			entities := [2]int{ev.a, ev.b}

			for entity in entities {
				if .Projectile in e[entity].traits {
					mtv := ev.data.mtv if entity == ev.a else -ev.data.mtv
					vel := linalg.normalize(mtv)
					vel *= 5.0

					append(
						&world.events,
						Particle_Event {
							origin = e[entity].position,
							particle_count = 30,
							initial_velocity = vel,
							max_variation = 4.0,
							lifetime = 1.0,
						},
					)

					enqueue_free(world, entity)
				}

				if .Damage in e[entity].traits {
					append(
						&world.events,
						Damage_Event {
							e[entity].damage,
							ev.b if ev.a == entity else ev.a
						}
					)
				}
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
		case Particle_Event:
			for i := 0; i < ev.particle_count; i += 1 {
				random_vec := [3]f32{rand.float32(), rand.float32(), rand.float32()} * 2.0 - 1.0
				random_vec = linalg.normalize(random_vec)
				vel := ev.initial_velocity + ev.max_variation * random_vec

				enqueue_create(
					world,
					{
						traits = {.Physical, .Dynamic, .Particle, .Collision},
						position = ev.origin,
						velocity = vel,
						shape = Cylinder {
							radius = 0.05,
							height = 0.1,
						},
						particle_state = {lifetime = ev.lifetime * (1 + rand.float32() - 0.5)},
						collides_with = {.Stage},
					},
				)
			}
		case Projectile_Event:
			enqueue_create(
				world,
				{
					traits = {.Physical, .Dynamic, .Particle, .Collision, .Projectile, .Damage},
					position = ev.origin,
					velocity = ev.velocity,
					shape = Cylinder {
						radius = 0.2,
						height = 0.3,
					},
					damage = 1.0,
					particle_state = {lifetime = 1.0},
					collides_with = ev.collides_with,
				},
			)
		case Damage_Event:
			if !(.Health in e[ev.entity].traits) {
				continue
			}

			e[ev.entity].health -= ev.amount

			if e[ev.entity].health <= 0 {
				append(
					&world.events,
					Death_Event {
						ev.entity
					}
				)
			}
		case Death_Event:
			enqueue_free(world, ev.entity)
		}
	}

	clear(&world.events)
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity, world: ^World, i: int) {
	switch s in e[i].shape {
	case Cylinder:
		pos := e[i].position

		rl.DrawCylinderWires(pos, s.radius, s.radius, s.height, 8, rl.GREEN)
	case AABB:
		rl.DrawCubeWiresV(e[i].position + [3]f32{0.0, s.size.y / 2.0, 0.0}, s.size, rl.GREEN)
	}
}

particle_system :: proc(e: ^#soa[dynamic]Entity, world: ^World, i: int) {
	e[i].particle_state.lifetime -= world.dt

	if e[i].particle_state.lifetime <= 0 {
		enqueue_free(world, i)
	}
}

debug_stats_task :: proc(e: ^#soa[dynamic]Entity, world: ^World) {
	x, y, h: i32 = 5, 0, 20

	rl.DrawFPS(x, y); y += h
	rl.DrawText(fmt.ctprintf("Max Entities: %v", len(e)), x, y, 20, rl.LIME); y += h
	pos := e[world.player].position
	coords := [3]int{int(pos.x), int(pos.y), int(pos.z)}
	rl.DrawText(fmt.ctprintf("Coords: %v", coords), x, y, 20, rl.LIME); y += h
	rl.DrawText(fmt.ctprintf("Rotation: %v", e[world.player].rotation), x, y, 20, rl.LIME); y += h
}

input_task :: proc(e: ^#soa[dynamic]Entity, world: ^World) {
	p1 := world.player

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
		rotated := rl.Vector3RotateByAxisAngle(
			direction,
			{0.0, 1.0, 0.0},
			e[world.player].rotation,
		)
		e[p1].velocity.xz = (rotated * e[p1].max_speed).xz
	} else {
		e[p1].velocity.xz = [2]f32{}
	}

	// Rotation
	e[p1].rotation -= rl.GetMouseDelta().x * world.mouse_sensitivity

	// Jumping
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		append(&world.events, Jump_Event{entity = p1})
	}

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		shape := e[p1].shape.(Cylinder)

		forward := linalg.normalize(world.camera.target - world.camera.position)

		origin := e[p1].position
		origin.y += shape.height - shape.radius
		origin += forward * shape.radius

		vel := forward * 30.0

		append(
			&world.events,
			Projectile_Event{origin = origin, velocity = vel, collides_with = {.Stage}},
		)
	}
}

camera_control_task :: proc(e: ^#soa[dynamic]Entity, world: ^World) {
	cam := &world.camera

	shape := e[world.player].shape.(Cylinder)

	head := e[world.player].position
	head.y += shape.height - shape.radius

	cam.target += head - cam.position
	cam.position = head

	rotate := rl.GetMouseDelta() * -1 * world.mouse_sensitivity
	rl.CameraYaw(cam, rotate.x, false)
	rl.CameraPitch(cam, rotate.y, true, false, false)
}

gravity_system :: proc(e: ^#soa[dynamic]Entity, world: ^World, i: int) {
	e[i].velocity.y -= 9.8 * 2 * world.dt
}
