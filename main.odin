package main

import rl "vendor:raylib"

main :: proc() {
	world: World = {
		camera = {target = {0.0, 0.0, 1.0}, up = {0.0, 1.0, 0.0}, fovy = 45.0},
	}
	defer destroy_world(world)

	rl.InitWindow(800, 600, "p2d-game")
	defer rl.CloseWindow()

	player := create_entity(
		&world,
		Entity {
			mask = {.Position, .Velocity, .Shape, .Movement_Control},
			shape = Capsule{radius = 1.0, height = 4.0},
			move_intent = {max_speed = 5.0},
			rotate_intent = {sensitivity = 0.05},
		},
	)

	enemy := create_entity(
		&world,
		Entity{mask = {.Position, .Shape}, shape = AABB{size = {3.0, 3.0, 3.0}}},
	)

	rl.DisableCursor()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		camera_control_task(&world, dt)
		movement_control_system(&world.entities)
		movement_system(&world.entities, dt)

		// FIXME
		player_head, _ := capsule_hemispheres([3]f32{}, world.entities[player].shape.(Capsule))
		world.camera.target.y += player_head - world.camera.position.y
		world.camera.position.y = player_head

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
