package main

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"

import "vendor:raylib"

Width :: 640
Height :: 480

SceneWidth :: 200
SceneHeight :: 200

cell_indices: [len(cells)]int

main :: proc() {
	raylib.InitWindow(Width, Height, "Cell Simulation")
	defer raylib.CloseWindow()

	camera := raylib.Camera2D {
		offset = {Width / 2.0, Height / 2.0},
		target = {0.0, 0.0},
		rotation = 0.0,
		zoom = 1.0,
	}

	for y in 0 .. SceneHeight - 1 {
		for x in 0 .. SceneWidth - 1 {
			cell_indices[x + y * SceneWidth] = x + y * SceneWidth
			cells[x + y * SceneWidth] = Cell {
				kind = (CellKind)(rand.uint32() % len(CellKind)),
				rectangle = raylib.Rectangle{
					x = f32(x) - SceneWidth / 2.0,
					y = f32(y) - SceneHeight / 2.0,
					width = 1,
					height = 1,
				},
			}
		}
	}

	selected_kind := CellKind.Air

	UpdateRate :: 1.0 / 30.0
	update_time: f32
	for !raylib.WindowShouldClose() {
		CameraSpeed :: 50.0
		if raylib.IsKeyDown(.W) {
			camera.target.y -= CameraSpeed / camera.zoom * raylib.GetFrameTime()
		}
		if raylib.IsKeyDown(.S) {
			camera.target.y += CameraSpeed / camera.zoom * raylib.GetFrameTime()
		}
		if raylib.IsKeyDown(.A) {
			camera.target.x -= CameraSpeed / camera.zoom * raylib.GetFrameTime()
		}
		if raylib.IsKeyDown(.D) {
			camera.target.x += CameraSpeed / camera.zoom * raylib.GetFrameTime()
		}

		if raylib.IsKeyPressed(.Q) {
			selected_kind = CellKind((int(selected_kind) + 1) % len(CellKind))
		}

		if raylib.IsKeyPressed(.C) {
			for cell in &cells {
				cell.kind = .Air
			}
		}

		camera.zoom += raylib.GetMouseWheelMove() * camera.zoom * 0.1
		camera.zoom = clamp(camera.zoom, 0.1, 10.0)

		if raylib.IsMouseButtonDown(.LEFT) {
			world_pos := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), camera)
			DrawSize :: 1
			for x in 0 .. DrawSize - 1 {
				for y in 0 .. DrawSize - 1 {
					cell := GetCell(
						int(math.floor(world_pos.x + SceneWidth / 2.0)) + x - DrawSize / 2,
						int(math.floor(world_pos.y + SceneHeight / 2.0)) + y - DrawSize / 2,
					)
					if cell != nil {
						cell.kind = selected_kind
					}
				}
			}
		}

		update_time += raylib.GetFrameTime()
		for update_time >= UpdateRate {
			rand.shuffle(cell_indices[:])
			for cell_index in cell_indices {
				x := cell_index % SceneWidth
				y := cell_index / SceneWidth
				current_cell := &cells[cell_index]
				UpdateCell(current_cell, x, y)
			}
			update_time -= UpdateRate
		}

		raylib.BeginDrawing()
		raylib.ClearBackground({51, 51, 51, 255})

		raylib.BeginMode2D(camera)
		for cell in cells {
			raylib.DrawRectangleRec(cell.rectangle, cell_colors[cell.kind])
		}
		raylib.EndMode2D()

		raylib.DrawText(
			strings.unsafe_string_to_cstring(
				fmt.tprintf("FPS: %.3f\x00", 1.0 / raylib.GetFrameTime()),
			),
			10,
			10,
			20,
			raylib.WHITE,
		)
		raylib.DrawText(
			strings.unsafe_string_to_cstring(fmt.tprintf("Selected Cell: %v\x00", selected_kind)),
			10,
			40,
			20,
			raylib.WHITE,
		)

		raylib.EndDrawing()
	}
}

RandomColor :: proc() -> raylib.Color {
	return {cast(u8)rand.uint32(), cast(u8)rand.uint32(), cast(u8)rand.uint32(), 255}
}
