package main

import "core:math"
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
			mask = {.Position, .Velocity, .Rotation, .Shape, .Controlled},
			shape = Capsule{radius = 1.0, height = 4.0},
			controlled = {move_intent = {max_speed = 5.0}, rotate_intent = {sensitivity = 0.01}},
		},
	)

	player_head, _ := capsule_hemispheres([3]f32{}, world.entities[player].shape.(Capsule))
	rl.CameraMoveUp(&world.camera, player_head)

	cam_fw := rl.GetCameraForward(&world.camera)
	world.entities[player].rotation = math.atan2(cam_fw.z, cam_fw.x)

	enemy := create_entity(
		&world,
		Entity{mask = {.Position, .Shape}, shape = AABB{size = {3.0, 3.0, 3.0}}},
	)

	rl.DisableCursor()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		input_task(&world)
		camera_control_task(&world, dt)
		control_system(&world.entities)
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
