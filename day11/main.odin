package day11

import "core:fmt"
import "core:mem"
import "core:runtime"
import "core:text/scanner"


Grid :: [dynamic][dynamic]u8;

// L: left, R: rigth, U: up, D: down, B: border, IN: inner
Position :: enum {
  LU,
  RU,
  LD,
  RD,
  BU,
  BD,
  BL,
  BR,
  IN,
}

Delta :: struct {
  x: int,
  y: int,
};

run_program :: proc(batch: string) -> (part1: int, part2: u64) {

  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  // Custom allocation
  buf: [50 * 1024]byte;
  a: mem.Arena;
  mem.init_arena(&a, buf[:]);

  allocator := mem.arena_allocator(&a);
  defer delete(buf[:], allocator);

  initial_grid := make_dynamic_array(Grid, allocator);
  single_row := make_dynamic_array([dynamic]u8, allocator);

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case 'L':
        append(&single_row, 0);
        scanner.next(s);
      case '.':
        append(&single_row, 127);
        scanner.next(s);
      case '\n':
        scanner.next(s);
        append(&initial_grid, single_row);
        single_row = make_dynamic_array([dynamic]u8, allocator);
      case:
        unreachable();
    }
  }

  // An identical state copy is required for part2
  initial_grid_clone := clone_grid(initial_grid);

  // PART1
  has_changed := true;
  for has_changed {
    has_changed = run_model(&initial_grid, false);
  }

  for i in 0..<len(initial_grid) {
    for j in 0..<len(initial_grid) {
      part1 += initial_grid[i][j] == 1 ? 1 : 0;
    }
  }

  // PART2
  has_changed = true;
  for has_changed {
    has_changed = run_model(&initial_grid_clone, true);
  }

  for i in 0..<len(initial_grid_clone) {
    for j in 0..<len(initial_grid_clone) {
      part2 += initial_grid_clone[i][j] == 1 ? 1 : 0;
    }
  }

  // Check arena usage
  /* fmt.printf("Current arena usage: %v bytes\n", a.peak_used); */

  return;
}

run_model :: proc(initial_grid: ^Grid, part2: bool) -> (has_changed: bool) {
  cnt: int;
  initial_grid_ref := clone_grid(initial_grid^);
  for i in 0..<len(initial_grid_ref) {
    for j in 0..<len(initial_grid_ref) {
      if initial_grid_ref[i][j] == 127 do continue;
      if j == 0 {
        if i == 0 {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .LU, part2);
        } else if i == len(initial_grid_ref)-1 {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .RU, part2);
        } else {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .BU, part2);
        }
      } else if j == len(initial_grid_ref)-1 {
        if i == 0 {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .LD, part2);
        } else if i == len(initial_grid_ref)-1 {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .RD, part2);
        } else {
          cnt = count_occupied_neighbors(initial_grid_ref, i, j, .BD, part2);
        }
      } else if i == 0 {
        cnt = count_occupied_neighbors(initial_grid_ref, i, j, .BL, part2);
      } else if i == len(initial_grid_ref)-1 {
        cnt = count_occupied_neighbors(initial_grid_ref, i, j, .BR, part2);
      } else {
        cnt = count_occupied_neighbors(initial_grid_ref, i, j, .IN, part2);
      }

      if initial_grid_ref[i][j] == 0 && cnt == 0 {
        initial_grid[i][j] = 1;
        has_changed = true;
      }
      if !part2 && initial_grid_ref[i][j] == 1 && cnt >= 4 {
        initial_grid[i][j] = 0;
        has_changed = true;
      }
      if part2 && initial_grid_ref[i][j] == 1 && cnt >= 5 {
        initial_grid[i][j] = 0;
        has_changed = true;
      }
    }
  }
  return;
}

count_occupied_deltas :: proc(grid: Grid, i, j:int, deltas: []Delta) -> (res: int) {
  for d in deltas {
    res += grid[i+d.x][j+d.y] == 1 ? 1 : 0;
  }
  return;
}

count_occupied_directions :: proc(grid: Grid, i, j:int, deltas: []Delta) -> (res: int) {
  for d in deltas {
    mult := 1;
    for grid[i+d.x*mult][j+d.y*mult] == 127 {
      mult += 1;
      if i+d.x*mult >= len(grid) || j+d.y*mult >= len(grid) || i+d.x*mult < 0 || j+d.y*mult < 0 {
        mult -= 1;
        break;
      };
    }
    res += grid[i+d.x*mult][j+d.y*mult] == 1 ? 1 : 0;
  }
  return;
}

count_occupied_neighbors :: proc(grid: Grid, i, j: int, pos: Position, part2: bool) -> (cnt: int) {
  deltas: []Delta;
  switch pos {
    case .LU:
      deltas = []Delta{{1, 0}, {0, 1}, {1, 1}};
    case .RU:
      deltas = []Delta{{-1, 0}, {0, 1}, {-1, 1}};
    case .LD:
      deltas = []Delta{{1, 0}, {0, -1}, {1, -1}};
    case .RD:
      deltas = []Delta{{-1, 0}, {0, -1}, {-1, -1}};
    case .BU:
      deltas = []Delta{{-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}};
    case .BL:
      deltas = []Delta{{0, -1}, {1, -1}, {1, 0}, {1, 1}, {0, 1}};
    case .BR:
      deltas = []Delta{{0, -1}, {-1, -1}, {-1, 0}, {-1, 1}, {0, 1}};
    case .BD:
      deltas = []Delta{{-1, 0}, {-1, -1}, {0, -1}, {1, -1}, {1, 0}};
    case .IN:
      deltas = []Delta{{1, 0}, {0, 1}, {1, 1}, {-1, 0}, {0, -1}, {-1, -1}, {1, -1}, {-1, 1}};
  }
  if part2 do return count_occupied_directions(grid, i, j, deltas[:]);
  return count_occupied_deltas(grid, i, j, deltas[:]);
}

clone_grid :: proc(grid: Grid) -> Grid {
  cloned := make_dynamic_array(Grid);
  for i in 0..<len(grid) {
    new_slice := make_dynamic_array_len([dynamic]u8, len(grid));
    runtime.copy_slice(new_slice[:], grid[i][:]);
    append(&cloned, new_slice);
  }
  return cloned;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
