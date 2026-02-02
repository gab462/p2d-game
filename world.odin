package main

import rl "vendor:raylib"

Entity :: struct {
	mask: Mask,
	position: Position,
	velocity: Velocity,
	shape: Shape,
	collision_mask: Collision_Mask,
}

World :: struct {
	entities: #soa[dynamic]Entity,
	camera: rl.Camera,
}

create_entity :: proc(world: ^World, e: Entity = {}) -> uint {
	append_soa(&world.entities, e)
	return len(world.entities) - 1
}

delete_world :: proc(world: World) {
	delete(world.entities)
}
