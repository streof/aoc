// NOTE: this is a VERY ineffecient implementation. Compiling in release mode is
// probably a good idea :)
package day17

import "core:fmt"
import "core:text/scanner"

TOTAL_BOOT_CYCLES :: 6;

Cube :: [4]int;
Cubes :: [dynamic]Cube;
Grid :: map[Cube]int;

part1 :: proc(batch: string) -> (res: int) {

  scan:= scanner.Scanner{};
  s := scanner.init(&scan, batch);

  grid := make(map[Cube]int);
  fill_grid(s, &grid);

  return run(grid, true);
}

part2 :: proc(batch: string) -> (res: int) {

  scan:= scanner.Scanner{};
  s := scanner.init(&scan, batch);

  grid := make(map[Cube]int);
  fill_grid(s, &grid);

  return run(grid, false);
}
init :: proc(cycle_current: Grid, part1: bool) -> (world_map: Grid) {

  // make sure that the world is big enough!
  world := construct_neighbors(TOTAL_BOOT_CYCLES+5, false, part1);
  neighbors := construct_neighbors(1, true, part1);

  state_neighbor : int;

  // init world map
  for l in world {
    world_map[l] = 0;
  }

  // update world map using the current state
  for l in world {
    for n in neighbors {
      state_neighbor = cycle_current[l+n];
      if state_neighbor != 0 {
        world_map[l+n] = state_neighbor;
      }
    }
  }
  return;
}

run :: proc(cycle_init: Grid, part1: bool) -> (sum: int) {
  //  i)    construct the world
  //  ii)   copy state to the world
  //  iii)  consider neighbors
  //  iv)   determine new state

  neighbors := construct_neighbors(1, true, part1);
  state_neighbor : int;
  to_activate, to_deactivate : Cubes;

  world_map := init(cycle_init, part1);

  for _ in 1..TOTAL_BOOT_CYCLES {

    // determine which cubes to activate
    for l, s in world_map {
      sum = 0;
      for n in neighbors {
        state_neighbor = world_map[n+l];
        sum += state_neighbor;
      }
      switch s {
        case 0:
          if sum == 3 {
            append(&to_activate, l);
          }
        case 1:
          if sum < 2 || sum > 3 {
            append(&to_deactivate, l);
          }
        case:
          unreachable();
      }
    }

    // activate / deactivate cubes
    for l in to_activate {
      world_map[l] = 1;
    }
    for l in to_deactivate {
      world_map[l] = 0;
    }

    // reset
    to_activate = {};
    to_deactivate = {};
  }

  for _, v in world_map {
    sum += v;
  }

  return;
}

construct_neighbors :: proc(gen: int, omit_origin: bool, part1: bool) -> (neighbors : Cubes) {
  for i in -gen..gen {
    for j in -gen..gen {
      for k in -gen..gen {
        if part1 {
          if omit_origin && i == 0 && j == 0 && k == 0 {
            continue;
          } else {
            pnt := Cube{i, j, k, 0};
            append(&neighbors, pnt);
          }
        } else {
          for l in -gen..gen {
            if omit_origin && i == 0 && j == 0 && k == 0 && l == 0 {
              continue;
            } else {
              pnt := Cube{i, j, k, l};
              append(&neighbors, pnt);
            }
          }
        }
      }
    }
  }
  return;
}

fill_grid :: proc(s: ^scanner.Scanner, grid: ^Grid) {
  using scanner;
  x, y : int;

  for peek(s) != EOF {
    switch peek(s) {
      case '#':
        cube := Cube{x, y, 0, 0};
        grid[cube] = 1;
        x += 1;
        next(s);
      case '.':
        cube := Cube{x, y, 0, 0};
        grid[cube] = 0;
        x += 1;
        next(s);
      case '\n':
        y -= 1;
        x = 0;
        next(s);
    }
  }
  return;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  fmt.println("Result part 1:", part1(batch));
  fmt.println("Result part 2:", part2(batch));
}
