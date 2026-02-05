package main

import rl "vendor:raylib"

main :: proc() {
	world: World = {
		camera = {position = {0.0, 10.0, -10.0}, up = {0.0, 1.0, 0.0}, fovy = 45.0},
	}
	defer delete_world(world)

	rl.InitWindow(800, 600, "odin-ecs")
	defer rl.CloseWindow()

	player := create_entity(
		&world,
		Entity {
			mask = {.Position, .Velocity, .Shape, .Movement_Control},
			move_intent = {max_speed = 5.0},
			shape = Capsule{radius = 1.0, height = 4.0},
		},
	)


	enemy := create_entity(
		&world,
		Entity{mask = {.Position, .Shape}, shape = AABB{size = {3.0, 3.0, 3.0}}},
	)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		input_task(&world)
		movement_control_system(&world.entities)
		movement_system(&world.entities, dt)
		collision_system(&world.entities)

		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.BeginMode3D(world.camera)
		rl.DrawGrid(100, 1)

		debug_draw_system(&world.entities)

		rl.EndMode3D()

		rl.EndDrawing()
	}
}
