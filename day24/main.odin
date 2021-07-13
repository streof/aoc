// NOTE: this is a VERY ineffecient implementation. Compiling in release mode is
// probably a good idea :)
package day24

import "core:fmt"
import "core:slice"
import "core:text/scanner"

Direction :: enum u8{e, se, sw, w, nw, ne};
Tile :: [Direction]u8;
Tiles :: [dynamic]Tile;

NUM_DAYS :: 100;

run_program :: proc(batch: string) -> (part1, part2: int) {

  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  t : Tile;
  black_tiles: Tiles;

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case 'e':
        t[.e] += 1;
        scanner.next(s);
      case 's':
        switch scanner.peek(s, 1) {
          case 'e':
            t[.se] += 1;
            scanner.next(s);
          case 'w':
            t[.sw] += 1;
            scanner.next(s);
          case:
            unreachable();
        }
        scanner.next(s);
      case 'w':
        t[.w] += 1;
        scanner.next(s);
      case 'n':
        switch scanner.peek(s, 1) {
          case 'w':
            t[.nw] += 1;
            scanner.next(s);
          case 'e':
            t[.ne] += 1;
            scanner.next(s);
          case:
            unreachable();
        }
        scanner.next(s);
      case '\n':
        apply_rules(&t);
        ind, found := slice.linear_search(black_tiles[:], t);
        if found {
          unordered_remove(&black_tiles, ind);
        } else {
          append(&black_tiles, t);
        }

        t = Tile{};
        scanner.next(s);
      case:
        unreachable();
    }
  }

  // PART1
  part1 = len(black_tiles);

  // PART2
  to_add, to_remove, neighbors_checked: Tiles;

  for _ in 1..NUM_DAYS {
    clear(&to_add);
    clear(&to_remove);
    clear(&neighbors_checked);

    for bt in black_tiles {
      cnt, tiles := check_adjacent_tiles(black_tiles, &neighbors_checked, bt);
      for tile in tiles {
        if !slice.contains(to_add[:], tile) do append(&to_add, tile);
      }
      if cnt == 0 || cnt > 2 {
        append(&to_remove, bt);
      }
    }

    // Update
    for bt in to_remove {
      ind, _ := slice.linear_search(black_tiles[:], bt);
      unordered_remove(&black_tiles, ind);
    }
    append_elems(&black_tiles, ..to_add[:]);
  }

  part2 = len(black_tiles);

  return;
}

check_adjacent_tiles :: proc(black_tiles: Tiles, neighbors_checked: ^Tiles, tile: Tile) -> (cnt: int, tiles: Tiles) {
  for dir in Direction {
    neighbor := tile;
    neighbor[dir] += 1;
    apply_rules(&neighbor);
    if slice.contains(neighbors_checked^[:], neighbor) {
      continue;
    } else {
      append(neighbors_checked, neighbor);
      if !slice.contains(black_tiles[:], neighbor) && count_adjacent_black_tiles(black_tiles, neighbor) == 2 do append(&tiles, neighbor);
    }
  }
  cnt = count_adjacent_black_tiles(black_tiles, tile);
  return;
}

count_adjacent_black_tiles :: proc(black_tiles: Tiles, tile: Tile) -> (cnt: int) {
  for dir in Direction {
    neighbor := tile;
    neighbor[dir] += 1;
    apply_rules(&neighbor);
    if slice.contains(black_tiles[:], neighbor) do cnt += 1;
  }
  return;
}

identity_rule :: proc(d1, d2: Direction, t: ^Tile) {
  if t[d1] > 0 && t[d2] > 0 {
    if t[d1] >= t[d2] {
      t[d1] -= t[d2];
      t[d2] = 0;
    } else {
      t[d2] -= t[d1];
      t[d1] = 0;
    }
  }
  return;
}

translation_rule :: proc(d1, d2, d3: Direction, t: ^Tile) {
  if t[d1] > 0 && t[d2] > 0 {
    if t[d1] >= t[d2] {
      t[d1] -= t[d2];
      t[d3] += t[d2];
      t[d2] = 0;
    } else {
      t[d2] -= t[d1];
      t[d3] += t[d1];
      t[d1] = 0;
    }
  }
  return;
}

apply_rules :: proc(t: ^Tile) {

  identity_rule(.e, .w, t);
  identity_rule(.sw, .ne, t);
  identity_rule(.se, .nw, t);

  translation_rule(.nw, .e, .ne, t);
  translation_rule(.se, .w, .sw, t);
  identity_rule(.sw, .ne, t);

  translation_rule(.w, .ne, .nw, t);
  translation_rule(.sw, .e, .se, t);
  identity_rule(.se, .nw, t);

  translation_rule(.sw, .nw, .w, t);
  translation_rule(.se, .ne, .e, t);
  identity_rule(.e, .w, t);

  return;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
