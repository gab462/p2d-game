package main

import rl "vendor:raylib"

main :: proc() {
	world := create_world()
	defer destroy_world(world)

	rl.InitWindow(800, 600, "p2d-game")
	defer rl.CloseWindow()

	world.player = create_entity(
		&world,
		Entity {
			traits = {.Physical, .Dynamic, .Rotation, .Controlled, .Collision},
			position = {0.0, 10.0, 0.0},
			max_speed = 5.0,
			shape = Cylinder{radius = 1.0, height = 4.0},
			jumps = {force = 10.0, count = 2},
			collides_with = {.Physical},
		},
	)

	player_shape := world.entities[world.player].shape.(Cylinder)
	rl.CameraMoveUp(&world.camera, player_shape.height - player_shape.radius)

	enemy := create_entity(
		&world,
		Entity{traits = {.Physical}, shape = AABB{size = {3.0, 3.0, 3.0}}},
	)

	ground := create_entity(
		&world,
		Entity {
			traits = {.Physical},
			position = {0.0, -1.0, 0.0},
			shape = AABB{size = {100.0, 1.0, 100.0}},
		},
	)

	lava := create_entity(
		&world,
		Entity {
			traits = {.Physical, .Damage},
			position = {10.0, 0.0, 10.0},
			shape = Cylinder{radius = 1.0, height = 4.0},
		},
	)

	rl.DisableCursor()

	for !rl.WindowShouldClose() {
		world.dt = rl.GetFrameTime()

		input_task(&world.entities, &world)
		run_system(&world, gravity_system, {.Dynamic})
		run_system(&world, movement_system, {.Physical, .Dynamic})
		run_system(&world, collision_system, {.Physical})
		event_processing_task(&world.entities, &world)
		camera_control_task(&world.entities, &world)
		debug_stats_task(&world.entities, &world)

		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(world.camera)
		rl.DrawGrid(100, 1)

		run_system(&world, debug_draw_system, {.Physical})

		rl.EndMode3D()

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
