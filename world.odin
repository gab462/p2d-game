package main

import rl "vendor:raylib"

Entity :: struct {
	traits:        Traits,
	position:      [3]f32,
	velocity:      [3]f32,
	rotation:      [2]f32, // yaw and pitch
	shape:         Shape,
	collides_with: Traits,
	controls:      Controls,
}

World :: struct {
	entities: #soa[dynamic]Entity,
	camera:   rl.Camera,
	events:   [dynamic]Event,
}

create_entity :: proc(world: ^World, e: Entity = {}) -> int {
	// FIXME: non-stable indices, add intrusive free-list
	append_soa(&world.entities, e)
	return len(world.entities) - 1
}

destroy_world :: proc(world: World) {
	delete(world.entities)
}
