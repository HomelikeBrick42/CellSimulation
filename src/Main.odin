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

CellKind :: enum {
	Air,
	Sand,
	Water,
}

cell_colors := [CellKind]raylib.Color {
	.Air   = raylib.BLACK,
	.Sand  = raylib.BEIGE,
	.Water = raylib.BLUE,
}

Cell :: struct {
	kind:      CellKind,
	rectangle: raylib.Rectangle,
}

cells: [SceneWidth * SceneHeight]Cell

GetCell :: proc(x: int, y: int) -> ^Cell {
	if x < 0 || x >= SceneWidth || y < 0 || y >= SceneHeight {
		return nil
	}
	return &cells[x + y * SceneWidth]
}

main :: proc() {
	raylib.InitWindow(Width, Height, "Cell Simulation")
	defer raylib.CloseWindow()

	camera := raylib.Camera2D {
		offset = {Width / 2.0, Height / 2.0},
		target = {0.0, 0.0},
		rotation = 0.0,
		zoom = 1.0,
	}

	cell_indices: [len(cells)]int
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

		camera.zoom += raylib.GetMouseWheelMove() * camera.zoom * 0.1
		camera.zoom = clamp(camera.zoom, 0.1, 10.0)

		if raylib.IsMouseButtonDown(.LEFT) {
			world_pos := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), camera)
			cell := GetCell(
				int(math.floor(world_pos.x + SceneWidth / 2.0)),
				int(math.floor(world_pos.y + SceneHeight / 2.0)),
			)
			if cell != nil {
				cell.kind = .Sand
			}
		}

		update_time += raylib.GetFrameTime()
		for update_time >= UpdateRate {
			rand.shuffle(cell_indices[:])
			for cell_index in cell_indices {
				x := cell_index % SceneWidth
				y := cell_index / SceneWidth
				current_cell := &cells[cell_index]
				switch current_cell.kind {
				case .Air:
				case .Sand:
					if below_cell := GetCell(x, y + 1); below_cell != nil && below_cell.kind == .Air {
						current_cell.kind = .Air
						below_cell.kind = .Sand
					} else {
						if rand.uint32() % 2 == 0 {
							if right_cell := GetCell(x + 1, y); right_cell != nil && right_cell.kind == .Air {
								if below_right_cell := GetCell(
									   x + 1,
									   y + 1,
								   ); below_right_cell != nil && below_right_cell.kind == .Air {
									current_cell.kind = .Air
									below_right_cell.kind = .Sand
								}
							}
						} else {
							if left_cell := GetCell(x - 1, y); left_cell != nil && left_cell.kind == .Air {
								if below_left_cell := GetCell(
									   x - 1,
									   y + 1,
								   ); below_left_cell != nil && below_left_cell.kind == .Air {
									current_cell.kind = .Air
									below_left_cell.kind = .Sand
								}
							}
						}
					}
				case .Water:
				}
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

		raylib.EndDrawing()
	}
}

RandomColor :: proc() -> raylib.Color {
	return {cast(u8)rand.uint32(), cast(u8)rand.uint32(), cast(u8)rand.uint32(), 255}
}
