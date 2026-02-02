package main

import rl "vendor:raylib"

movement_system :: proc(e: ^#soa[dynamic]Entity, dt: f32) {
	mask: Mask = { .Position, .Velocity }

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) { continue }
		e[i].position += e[i].velocity * dt
	}
}

collision_system :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = { .Position, .Shape, .Collision_Mask }

	for i := 0; i < len(e) - 1; i += 1 {
		if !(e[i].mask >= mask) { continue }

		for j := i + 1; j < len(e); j += 1 {
			if e[i].collision_mask & e[j].mask == (Mask{}) { continue }

			collide := collision(e[i].position, e[j].position, e[i].shape, e[j].shape)
			// TODO: save collision
		}
	}
}

debug_draw_system :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = { .Position, .Shape }

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) { continue }

		switch s in e[i].shape {
		case Capsule:
			toe := e[i].position
			toe.y += s.radius

			head := e[i].position
			head.y += s.height - s.radius

			rl.DrawCapsuleWires(toe, head, s.radius, 8, 8, rl.GREEN)
		case AABB:
			rl.DrawCubeWiresV(e[i].position, s.size, rl.GREEN)
		}
	}
}
