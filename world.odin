package main

import rl "vendor:raylib"

Entity :: struct {
	traits:        Traits,
	position:      [3]f32,
	velocity:      [3]f32,
	max_speed:     f32,
	rotation:      f32, // yaw only
	shape:         Shape,
	collides_with: Traits,
	jumps:         Jumps,
	next_free:     int, // intrusive list
}

World :: struct {
	entities:          #soa[dynamic]Entity,
	player:            int,
	dt:                f32,
	camera:            rl.Camera,
	mouse_sensitivity: f32,
	events:            [dynamic]Event,
	first_free:        int,
}

create_world :: proc() -> World {
	world: World = {
		camera = {target = {0.0, 0.0, 1.0}, up = {0.0, 1.0, 0.0}, fovy = 45.0},
		mouse_sensitivity = 0.01,
	}

	// nil entity
	append_soa(&world.entities, Entity{})

	return world
}

create_entity :: proc(world: ^World, e: Entity = {}) -> int {
	if world.first_free != 0 {
		idx := world.first_free

		world.first_free = world.entities[idx].next_free
		world.entities[idx] = e

		return idx
	} else {
		append_soa(&world.entities, e)

		return len(world.entities) - 1
	}
}

free_entity :: proc(world: ^World, idx: int) {
	assert(idx != 0) // cannot free nil entity
	if .Inactive in world.entities[idx].traits {return} 	// already free

	world.entities[idx].traits += {.Inactive}
	world.entities[idx].next_free = world.first_free
	world.first_free = idx
}

destroy_world :: proc(world: World) {
	delete(world.entities)
}
