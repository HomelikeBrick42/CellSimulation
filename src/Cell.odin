package main

import "core:math/rand"

import "vendor:raylib"

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

GetCell :: proc(x, y: int) -> ^Cell {
	if x < 0 || x >= SceneWidth || y < 0 || y >= SceneHeight {
		return nil
	}
	return &cells[x + y * SceneWidth]
}

SwapCell :: proc(a, b: ^Cell) {
	a.kind, b.kind = b.kind, a.kind
}

UpdateCell :: proc(current_cell: ^Cell, x, y: int) {
	assert(current_cell != nil)
	switch current_cell.kind {
	case .Air:
	case .Sand:
		if below_cell := GetCell(
			   x,
			   y + 1,
		   ); below_cell != nil && (below_cell.kind == .Air || below_cell.kind == .Water) {
			SwapCell(current_cell, below_cell)
		}
		else {
			if rand.uint32() % 2 == 0 {
				if right_cell := GetCell(
					   x + 1,
					   y,
				   ); right_cell != nil && (right_cell.kind == .Air || right_cell.kind == .Water) {
					if below_right_cell := GetCell(
						   x + 1,
						   y + 1,
					   ); below_right_cell != nil && (below_right_cell.kind == .Air || below_right_cell.kind ==
					   .Water) {
						SwapCell(current_cell, below_right_cell)
					}
				}
			} else {
				if left_cell := GetCell(
					   x - 1,
					   y,
				   ); left_cell != nil && (left_cell.kind == .Air || left_cell.kind == .Water) {
					if below_left_cell := GetCell(
						   x - 1,
						   y + 1,
					   ); below_left_cell != nil && (below_left_cell.kind == .Air || below_left_cell.kind ==
					   .Water) {
						SwapCell(current_cell, below_left_cell)
					}
				}
			}
		}
	case .Water:
		if below_cell := GetCell(x, y + 1); below_cell != nil && below_cell.kind == .Air {
			SwapCell(current_cell, below_cell)
		} else {
			if rand.uint32() % 2 == 0 {
				if right_cell := GetCell(x + 1, y); right_cell != nil && right_cell.kind == .Air {
					SwapCell(current_cell, right_cell)
				}
			} else {
				if left_cell := GetCell(x - 1, y); left_cell != nil && left_cell.kind == .Air {
					SwapCell(current_cell, left_cell)
				}
			}
		}
	}
}
