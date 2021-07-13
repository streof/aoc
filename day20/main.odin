package day20

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:math"
import "core:mem"
import "core:text/scanner"


SIZE_CONTENT :: 8;

VecBorder :: [SIZE_CONTENT+2]u8;
VecContent :: [dynamic]u8;

Direction :: enum u8 {up, right, down, left};
Square :: [Direction]VecBorder;
Content :: [dynamic]VecContent;

Tile :: struct {
  sqr: Square,
  cont: Content,
  id: u64,
};

Lookup :: map[u64]^Config;
Orientation :: enum u8 {r0, r1, r2, r3, fr0, fr1, fr2, fr3};
Config :: [Orientation]^Tile;

Matches :: map[u64]^MatchingEdges;
MatchingEdges :: [dynamic]^MatchingEdge;

MatchingEdge :: struct {
  tile_id: u64,
  direction: [dynamic]Dir2,
  orientation: [dynamic]Orien2,
};

Dir2 :: [2]Direction;
Orien2 :: [2]Orientation;

Neighbors :: struct {
  ids: [dynamic]u64,
  cnt: u8,
}

Tiles :: struct {
  corner: [dynamic]u64,
  border: [dynamic]u64,
  inner: [dynamic]u64,
}

TileType :: enum {
  Corner,
  Border,
  Inner,
}

TilePosition :: struct {
  row: int,
  col: int,
}

TileArrangement :: struct {
  id: u64,
  orientation: Orientation,
  cont: Content,
}

SeaMonster :: map[int][dynamic]u8;

run_program :: proc(batch: string) -> (part1: u64, part2: u64) {
  using scanner;

  scn := Scanner{};
  s := init(&scn, batch);

  height, width: u8;
  tile : ^Tile;
  lookup : Lookup;
  num : u64;

  // Custom allocator for storing the tiles
  buf: [700 * 1024]byte;
  a: mem.Arena;
  mem.init_arena(&a, buf[:]);

  allocator := mem.arena_allocator(&a);
  defer delete(buf[:], allocator);

  conf := new_clone(Config{}, allocator);

  // Define default tile
  sqr0 := Square {
    .up = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    .right = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    .down = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    .left = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  };

  // Scan and store the tiles
  for peek(s) != EOF {
    switch peek(s) {
      case '0'..'9':
        // create a tile with its associated id
        scan(s);
        tkn := token_text(s);
        num, _ = strconv.parse_u64(tkn);

        cont0 := init_content(SIZE_CONTENT, allocator);
        tile = new_clone(Tile{sqr = sqr0, cont = cont0, id = num}, allocator);

        conf = new_clone(Config{}, allocator);
        lookup[num] = conf;
        lookup[num][.r0] = tile;

        height = 0;
        scan(s); // skip newline after scanning the id
        next(s);
      case '.':
        width += 1;
        next(s);
      case '#':
        if height == 0 {
          tile.sqr[.up][width] = 1;
        }
        if height == 9 {
          tile.sqr[.down][9 - width] = 1;
        }
        if width == 0 {
          tile.sqr[.left][9 - height] = 1;
        }
        if width == 9 {
          tile.sqr[.right][height] = 1;
        }
        if width > 0 && width < 9 && height > 0 && height < 9 {
          tile.cont[height-1][width-1] = 1;
        }
        width += 1;
        next(s);
      case '\n':
        width = 0;
        height += 1;
        next(s);
      case:
        next(s);
    }
  }

  generate_tile_configurations(&lookup, sqr0, allocator);
  matches := get_matching_edges(lookup, allocator);

  // Determine possible neighbors
  tile_neighbors : map[u64]Neighbors;

  for k, v in matches {
    _tmp := make([dynamic]u64);
    for i in v {
      if slice.contains(_tmp[:], i.tile_id) do continue;
      append(&_tmp, i.tile_id);
    }
    tile_neighbors[k] = Neighbors{ids = _tmp, cnt = u8(len(_tmp))};
  }

  // PART1
  part1 = 1;
  tiles := Tiles{};
  for k, v in tile_neighbors {
    switch v.cnt {
      case 2:
        append(&tiles.corner, k);
        part1 *= k;
      case 3:
        append(&tiles.border, k);
      case 4:
        append(&tiles.inner, k);
      case:
        unreachable();
    }
  }

  // PART2
  tiles_per_row := 2 + len(tiles.border) / 4;
  arrangement := make_dynamic_array([dynamic]^TileArrangement, allocator);
  pos : TilePosition;

  // Arrange all tiles correctly
  for {
    // Restrict search space by considering type next tile
    if (pos == TilePosition{0, 0} || pos == TilePosition{0, tiles_per_row-1} ||
    pos == TilePosition{tiles_per_row-1, 0} || pos == TilePosition{tiles_per_row-1, tiles_per_row-1}) {
      place_next_tile(&tiles, .Corner, pos, &arrangement, matches, tiles_per_row, allocator);
    } else if (pos.row == 0 || pos.row  == tiles_per_row - 1 || pos.col == 0 || pos.col  == tiles_per_row - 1) {
      place_next_tile(&tiles, .Border, pos, &arrangement, matches, tiles_per_row, allocator);
    } else {
      place_next_tile(&tiles, .Inner, pos, &arrangement, matches, tiles_per_row, allocator);
    }

    if (pos.row == tiles_per_row - 1) && (pos.col == tiles_per_row - 1) do break;
    _increment(&pos, tiles_per_row);
  }

  // Create image and sea monster
  image := construct_image(arrangement, lookup, tiles_per_row, allocator);
  sea_monster : SeaMonster;
  sea_monster[0] = {18};
  sea_monster[1] = {0, 5, 6, 11, 12, 17, 18, 19};
  sea_monster[2] = {1, 4, 7, 10, 13, 16};

  // Count hashes to get water roughness
  hashes_found := hashes_modulo_sea_monsters(image, sea_monster);
  hashes_image : u64;
  for i in image {
    hashes_image += u64(math.sum(i[:]));
  }

  part2 = hashes_image - hashes_found;

  // Check arena usage
  /* fmt.printf("Current arena usage: %v bytes\n", a.peak_used); */

  return;
}

hashes_modulo_sea_monsters :: proc(image: [dynamic][dynamic]u8, sea_monster: SeaMonster) -> u64 {
  flip : bool;
  rot: u8;
  hashes_found_total: u64;

  // Search through all 8 possible configurations
  for i in 0..<SIZE_CONTENT {
    mid := SIZE_CONTENT / 2;
    mod := i % mid;
    if mod == 0 do rot = 0;
    if mod == 1 || mod == mid + 1 do rot = 1;
    flip = i == mid ? true : false;
    flip_and_rotate_content(image, rot, flip);
    _, _hashes_found := find_sea_monsters_of_size_20(image, sea_monster);
    hashes_found_total += _hashes_found;
  }
  return hashes_found_total;
}

construct_image :: proc(arrangement: [dynamic]^TileArrangement, lookup: Lookup, tiles_per_row: int, allocator: mem.Allocator) -> (image: [dynamic][dynamic]u8) {

  image = make_dynamic_array_len([dynamic][dynamic]u8, tiles_per_row * SIZE_CONTENT, allocator);
  mult : u8;

  // Change tiles to correct orientation before constructing final image
  for a, ind in arrangement {
    initial_content := lookup[a.id]^[.r0].cont;
    switch a.orientation {
      case .r0:
        a.cont = initial_content;
      case .r1:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 1, false);
      case .r2:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 2, false);
      case .r3:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 3, false);
      case .fr0:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 0, true);
      case .fr1:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 1, true);
      case .fr2:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 2, true);
      case .fr3:
        a.cont = initial_content;
        flip_and_rotate_content(a.cont, 3, true);
    }

    if ind % tiles_per_row == 0 && ind != 0 do mult += 1;
    for i in 0..<SIZE_CONTENT {
      append_elems(&image[u8(i) + mult*SIZE_CONTENT], ..a.cont[i][:]);
    }
  }
  return;
}

find_sea_monsters_of_size_20 :: proc(image: [dynamic][dynamic]u8, sea_monster: SeaMonster) -> (u64, u64) {
  dim_monster := 20;
  dim_image := len(image[0]);
  max_shift := u8(dim_image - dim_monster);

  len_up := len(sea_monster[0]);
  len_mid := len(sea_monster[1]);
  len_low := len(sea_monster[2]);

  len_total := len_up + len_mid + len_low;
  found: u64;

  for _, ind in image {
    if ind >= 2 {
      for s in 0..max_shift {
        cnt_up, cnt_mid, cnt_low : int;
        for k, v in sea_monster {
          switch k {
            case 0:
              for v0 in v do cnt_up += image[ind-2][v0+s] == 1 ? 1 : 0;
            case 1:
              for v1 in v do cnt_mid += image[ind-1][v1+s] == 1 ? 1 : 0;
            case 2:
              for v2 in v do cnt_low += image[ind][v2+s] == 1 ? 1 : 0;
          }
        }
        if cnt_up == len_up && cnt_mid == len_mid && cnt_low == len_low do found += 1;
      }
    }
  }
  return found, found * u64(len_total);
}

place_next_tile :: proc(using tiles: ^Tiles, type: TileType, pos: TilePosition, arrangement: ^[dynamic]^TileArrangement, matches: Matches, size: int, allocator: mem.Allocator) {

  prev_tile, prev_tile_same_col : ^TileArrangement;
  matches_prev_tile, matches_prev_tile_same_col : ^MatchingEdges;

  // Get previous tile and orietation
  if len(arrangement) > 0 {
    prev_tile = arrangement[len(arrangement)-1];
    matches_prev_tile = matches[prev_tile.id];
  }

  if len(arrangement) >= size {
    prev_tile_same_col = arrangement[len(arrangement) - size];
    matches_prev_tile_same_col = matches[prev_tile_same_col.id];
  }

  cont0 := init_content(SIZE_CONTENT, allocator);

  switch type {
    case .Corner:
      if (pos == TilePosition{0, 0}) {
        next_tile := pop_front(&corner);
        // It does not matter which corner we start with as the final image will be flipped and rotated anyway. The orientation however, does matter!
        // Choose the first orientation such that, it matches:
        // i)  a border on the right, and
        // ii) a border from beneath
        // Apply similar logic to the remaining cases/branches
        outer_corner_left_up: for match in matches[next_tile] {
          for match2 in matches[next_tile] {
            if (match.direction[0][0] == .right && match2.direction[0][0] == .down && match.tile_id != match2.tile_id && match.orientation[0][0] == match2.orientation[0][0]) {
              tile_to_place := new_clone(TileArrangement{id=next_tile, orientation=match.orientation[0][0], cont=cont0}, allocator);
              append(arrangement, tile_to_place);
              break outer_corner_left_up;
            } else do continue;
          }
        }
      } else if (pos == TilePosition{0, size-1}) {
        outer_corner_right_up: for tile, ind in corner {
          for match in matches_prev_tile {
            if tile == match.tile_id && match.direction[0][0] == .right && match.orientation[0][0] == prev_tile.orientation {
              ordered_remove(&corner, ind);
              tile_to_place := new_clone(TileArrangement{id=tile, orientation=match.orientation[0][1], cont=cont0}, allocator);
              append(arrangement, tile_to_place);
              break outer_corner_right_up;
            } else do continue;
          }
        }
      } else if (pos == TilePosition{size-1, 0}) {
        outer_corner_left_down: for tile, ind in corner {
          for match in matches_prev_tile_same_col {
            if tile == match.tile_id && match.direction[0][0] == .down && match.orientation[0][0] == prev_tile_same_col.orientation {
              ordered_remove(&corner, ind);
              tile_to_place := new_clone(TileArrangement{id=tile, orientation=match.orientation[0][1], cont=cont0}, allocator);
              append(arrangement, tile_to_place);
              break outer_corner_left_down;
            } else do continue;
          }
        }
      } else {
        next_tile := pop_front(&corner);
        outer_corner_right_down: for match_col in matches_prev_tile_same_col {
          if next_tile == match_col.tile_id && match_col.direction[0][0] == .down && match_col.orientation[0][0] == prev_tile_same_col.orientation {
            for match in matches_prev_tile {
              if next_tile == match.tile_id && match.direction[0][0] == .right && match.orientation[0][0] == prev_tile.orientation {
                tile_to_place := new_clone(TileArrangement{id=next_tile, orientation=match_col.orientation[0][1], cont=cont0});
                append(arrangement, tile_to_place);
                assert(match.orientation[0][1] == match_col.orientation[0][1]);
                break outer_corner_right_down;
              } else do continue;
            }
          } else do continue;
        }
      }
    case .Border:
      if pos.col == 0 {
        outer_border_left: for tile, ind in border {
          for match in matches_prev_tile_same_col {
            if tile == match.tile_id && match.direction[0][0] == .down && match.orientation[0][0] == prev_tile_same_col.orientation {
              ordered_remove(&border, ind);
              tile_to_place := new_clone(TileArrangement{id=tile, orientation=match.orientation[0][1], cont=cont0}, allocator);
              append(arrangement, tile_to_place);
              break outer_border_left;
            } else do continue;
          }
        }
      } else {
        outer_border: for tile, ind in border {
          for match in matches_prev_tile {
            if tile == match.tile_id && match.direction[0][0] == .right && match.orientation[0][0] == prev_tile.orientation {
              ordered_remove(&border, ind);
              tile_to_place := new_clone(TileArrangement{id=tile, orientation=match.orientation[0][1], cont=cont0}, allocator);
              append(arrangement, tile_to_place);
              break outer_border;
            } else do continue;
          }
        }
      }
    case .Inner:
      outer_inner: for tile, ind in inner {
        for match_col in matches_prev_tile_same_col {
          if tile == match_col.tile_id && match_col.direction[0][0] == .down && match_col.orientation[0][0] == prev_tile_same_col.orientation {
            for match in matches_prev_tile {
              if tile == match.tile_id && match.direction[0][0] == .right && match.orientation[0][0] == prev_tile.orientation {
                ordered_remove(&inner, ind);
                tile_to_place := new_clone(TileArrangement{id=tile, orientation=match_col.orientation[0][1], cont=cont0}, allocator);
                append(arrangement, tile_to_place);
                assert(match.orientation[0][1] == match_col.orientation[0][1]);
                break outer_inner;
              } else do continue;
            }
          } else do continue;
        }
      }
  }
  return;
}

_increment :: proc(using pos: ^TilePosition, size: int) {
  if col == size - 1 {
    row += 1;
    col = 0;
    return;
  }
  col += 1;
  return;
}

// For each tile, generate all 8 possible tile configurations
generate_tile_configurations :: proc(lookup: ^Lookup, sqr0: Square, allocator: mem.Allocator) {
  for k, v in lookup {
    for _, j in v {
      tile := new_clone(Tile{sqr = sqr0, id = k}, allocator);
      #partial switch j { // .r0 has already been set
      case .r1:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 1, false);
      case .r2:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 2, false);
      case .r3:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 3, false);
      case .fr0:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 0, true);
      case .fr1:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 1, true);
      case .fr2:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 2, true);
      case .fr3:
        lookup[k][j] = tile;
        flip_and_rotate_sqr(&tile.sqr, v[.r0].sqr, 3, true);
      }
    }
  }
  return;
}

// For each unique pair of tiles, store mathching edges and corresponding orientation
get_matching_edges :: proc(lookup: Lookup, allocator: mem.Allocator) -> (matches: Matches) {

  seen := make_dynamic_array([dynamic]u64, allocator);

  for k1, v1 in lookup {
    append(&seen, k1);
    for k2, v2 in lookup {
      if slice.contains(seen[:], k2) do continue;

      check_and_create(&matches, k1, k2, allocator);
      // Iterate over all edges for given pair of tiles (k1, k2).
      /* fmt.printf("\nGot combination %v, %v\n", k1, k2); */
      loop: for i1, j1 in v1 {
        for i2, j2 in v2 {

          i2_l, i2_r, i2_u, i2_d := reverse_sqr(i2.sqr);
          if i1.sqr[.right] == i2_l {
            /* fmt.printf("Got a match: right %v - left %v\n", j1, j2); */
            assign_value(&matches, k1, k2, Dir2{.right, .left}, Orien2{j1, j2}, allocator);
            assign_value(&matches, k2, k1, Dir2{.left, .right}, Orien2{j2, j1}, allocator);
          }

          if i1.sqr[.left] == i2_r {
            /* fmt.printf("Got a match: left %v - right %v\n", j1, j2); */
            assign_value(&matches, k1, k2, Dir2{.left, .right}, Orien2{j1, j2}, allocator);
            assign_value(&matches, k2, k1, Dir2{.right, .left}, Orien2{j2, j1}, allocator);
          }

          if i1.sqr[.down] == i2_u {
            /* fmt.printf("Got a match: down %v - up %vt\n", j1, j2); */
            assign_value(&matches, k1, k2, Dir2{.down, .up}, Orien2{j1, j2}, allocator);
            assign_value(&matches, k2, k1, Dir2{.up, .down}, Orien2{j2, j1}, allocator);
          }

          if i1.sqr[.up] == i2_d {
            /* fmt.printf("Got a match: up %v - down %vt\n", j1, j2); */
            assign_value(&matches, k1, k2, Dir2{.up, .down}, Orien2{j1, j2}, allocator);
            assign_value(&matches, k2, k1, Dir2{.down, .up}, Orien2{j2, j1}, allocator);
          }
        }
      }
    }
  }
  return;
}


assign_value :: proc(matches: ^Matches, id: u64, neighbor_id: u64, dir: Dir2, orien: Orien2, allocator: mem.Allocator) {

  edge := new_clone(MatchingEdge{tile_id = neighbor_id}, allocator);

  append(&edge.direction, dir);
  append(&edge.orientation, orien);
  append(matches[id], edge);
  return;
}
check_and_create :: proc(matches: ^Matches, k1: u64, k2: u64, allocator: mem.Allocator) {

  if matches[k1] == nil {
    matching_edges := new_clone(MatchingEdges{}, allocator);
    matches[k1] = matching_edges;
  }

  if matches[k2] == nil {
    matching_edges := new_clone(MatchingEdges{}, allocator);
    matches[k2] = matching_edges;
  }

  return;
}

init_content :: proc(length: int, allocator: mem.Allocator) -> (res: [dynamic][dynamic]u8) {
  res = make_dynamic_array_len([dynamic][dynamic]u8, length, allocator);
  for i in 0..<len(res) {
    inner :=  make_dynamic_array_len([dynamic]u8, length, allocator);
    res[i] = inner;
  }
  return;
}

reverse_sqr :: proc(sqr: Square) -> (d1, d2, d3, d4: VecBorder) {
  d1 = sqr[.left];
  d2 = sqr[.right];
  d3 = sqr[.up];
  d4 = sqr[.down];

  slice.reverse(d1[:]);
  slice.reverse(d2[:]);
  slice.reverse(d3[:]);
  slice.reverse(d4[:]);
  return;
}

flip_and_rotate_sqr :: proc(sqr: ^Square, ref: Square, $rot: uint, flip: bool) where rot < 4 {

  if !flip {
    _rotate_sqr(sqr, ref, rot);
    return;
  }

  _flip_sqr(sqr, ref, rot);
  _sqr:= sqr^;
  _rotate_sqr(sqr, _sqr, rot);

  return;
}

_rotate_sqr :: proc(sqr: ^Square, ref: Square, rot: uint) {
  if rot == 0 do return;

  // compiler does not like it; thinks the index is out of bounds
  /* sqr[.up] = ref[.up + auto_cast (4 - rot)]; */

  sqr[.left] = ref[.left - auto_cast rot];

  switch rot {
    case 1:
      sqr[.up] = ref[.up + auto_cast 3];
      sqr[.right] = ref[.right - auto_cast 1];
      sqr[.down] = ref[.down - auto_cast 1];
    case 2:
      sqr[.up] = ref[.up + auto_cast 2];
      sqr[.right] = ref[.right + auto_cast 2];
      sqr[.down] = ref[.down - auto_cast 2];
    case 3:
      sqr[.up] = ref[.up + auto_cast 1];
      sqr[.right] = ref[.right + auto_cast 1];
      sqr[.down] = ref[.down + auto_cast 1];
  }
  return;
}

_flip_sqr :: proc(sqr: ^Square, ref: Square, rot: uint) {

  sqr[.up] = ref[.up];
  sqr[.right] = ref[.left];
  sqr[.down] = ref[.down];
  sqr[.left] = ref[.right];

  slice.reverse(sqr[.up][:]);
  slice.reverse(sqr[.right][:]);
  slice.reverse(sqr[.down][:]);
  slice.reverse(sqr[.left][:]);

  return;
}

flip_and_rotate_content :: proc(array: [dynamic]$T/[dynamic]$E, rot: u8, flip: bool) {
  if !flip {
    _rotate_content(array, rot);
    return;
  }

  _flip_content(array);
  _rotate_content(array, rot);
  return;
}

_flip_content :: proc(array: [dynamic]$T/[dynamic]$E) {
  for i in 0..<len(array) {
    slice.reverse(array[i][:]);
  }
}

_rotate_content :: proc(array: [dynamic]$T/[dynamic]$E, rot: u8) {
  rot := rot;
  for _ in 0..<rot {
    _rotate_once(array[:]);
  }
  return;
}

_rotate_once :: proc(array: []$T/[dynamic]$E) {
  _swap_diag_slice(array);
  _reverse_rows_slice(array);
}

_reverse_rows_slice :: proc(array: []$T/[dynamic]$E) {
  for i in 0..<len(array) {
    slice.reverse(array[i][:]);
  }
}

_swap_diag_slice :: proc(array: []$T/[dynamic]$E) {
  for i in 0..<len(array) {
    for j in 0..<i {
      array[i][j], array[j][i] = array[j][i], array[i][j];
    }
  }
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
