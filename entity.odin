package main

Entity :: struct {
	mask: Mask,
	position: Position,
	velocity: Velocity,
	shape: Shape,
	collision: Collision_Mask,
}

create_entity :: proc(entities: ^#soa[dynamic]Entity, e: Entity = {}) -> uint {
	append_soa(entities, e)
	return len(entities) - 1
}
