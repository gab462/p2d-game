package main

import "core:math"
import rl "vendor:raylib"

main :: proc() {
	world := create_world()
	defer destroy_world(world)

	rl.InitWindow(800, 600, "p2d-game")
	defer rl.CloseWindow()

	player := create_entity(
		&world,
		Entity {
			traits = {.Physical, .Dynamic, .Rotation, .Controlled, .Collision},
			position = {0.0, 10.0, 0.0},
			shape = Cylinder{radius = 1.0, height = 4.0},
			controls = {
				move_intent = {max_speed = 5.0},
				rotate_intent = {sensitivity = 0.01},
				jump_intent = {force = 10.0, max_count = 2},
			},
			collides_with = {.Physical},
		},
	)

	player_shape := world.entities[player].shape.(Cylinder)
	rl.CameraMoveUp(&world.camera, player_shape.height - player_shape.radius)

	cam_fw := rl.GetCameraForward(&world.camera)
	world.entities[player].rotation = math.atan2(cam_fw.z, cam_fw.x)

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

	gravity: f32 = 9.8 * 2

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		input_task(&world, player)
		gravity_system(&world.entities, gravity, dt)
		control_system(&world.entities)
		movement_system(&world.entities, dt)
		collision_system(&world.entities, &world.events)
		event_processing_task(&world.entities, &world.events, player)
		camera_control_task(&world, player)

		debug_stats_task(&world.entities)

		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(world.camera)
		rl.DrawGrid(100, 1)

		debug_draw_system(&world.entities)

		rl.EndMode3D()

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
