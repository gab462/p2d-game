package main

import rl "vendor:raylib"

Entity :: struct {
	mask:           Mask,
	position:       Position,
	velocity:       Velocity,
	rotation:       Rotation,
	shape:          Shape,
	collision_mask: Collision_Mask,
	controlled:     Controlled,
}

World :: struct {
	entities: #soa[dynamic]Entity,
	camera:   rl.Camera,
	events: [dynamic]Event,
}

create_entity :: proc(world: ^World, e: Entity = {}) -> int {
	append_soa(&world.entities, e)
	return len(world.entities) - 1
}

destroy_world :: proc(world: World) {
	delete(world.entities)
}
