package main

movement :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = { .Position, .Velocity }

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) { continue }

		e[i].position += e[i].velocity
	}
}

debug_draw :: proc(e: ^#soa[dynamic]Entity) {
	mask: Mask = { .Position, .Shape }

	for i := 0; i < len(e); i += 1 {
		if !(e[i].mask >= mask) { continue }

		e[i].position += e[i].velocity
	}
}
