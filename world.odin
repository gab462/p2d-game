package main

import rl "vendor:raylib"

Entity :: struct {
	traits:         Traits,
	position:       [3]f32,
	velocity:       [3]f32,
	max_speed:      f32, // for controls
	rotation:       f32, // yaw only
	shape:          Shape,
	collides_with:  Traits,
	jumps:          Jumps,
	particle_state: Particle_State,
	next_free:      int, // intrusive list
}

World :: struct {
	entities:          #soa[dynamic]Entity,
	player:            int,
	dt:                f32,
	camera:            rl.Camera,
	mouse_sensitivity: f32,
	events:            [dynamic]Event,
	first_free:        int,
	to_free:           [dynamic]int,
	to_create:         [dynamic]Entity,
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

enqueue_create :: proc(world: ^World, e: Entity) {
	append(&world.to_create, e)
}

enqueue_free :: proc(world: ^World, idx: int) {
	append(&world.to_free, idx)
}

refresh_world :: proc(world: ^World) {
	for i in world.to_free {
		free_entity(world, i)
	}

	for e in world.to_create {
		create_entity(world, e)
	}

	clear(&world.to_free)
	clear(&world.to_create)
}

destroy_world :: proc(world: World) {
	delete(world.entities)
}
