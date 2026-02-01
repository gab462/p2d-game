package main

import rl "vendor:raylib"

main :: proc() {
	entities: #soa[dynamic]Entity

	rl.InitWindow(800, 600, "odin-ecs")
	defer rl.CloseWindow()

	player := create_entity(&entities, Entity {
		velocity={ 1.0, 0.0, 0.0 },
	})

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.EndDrawing()
	}
}
