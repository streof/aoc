package day12

import "core:fmt"
import "core:strconv"
import "core:text/scanner"
import "core:unicode/utf8"

Direction :: enum {North, East, South, West};
Turn :: enum {Left, Rigth};

Position :: struct {
  x : int,
  y : int,
}

Ship :: struct {
  using pos : Position,
  d : Direction,
}

WayPoint :: struct {
  using pos : Position,
  d_x: Direction,
  d_y: Direction,
}

run_program :: proc(batch: string) -> (part1, part2: int) {
  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  pos_ship := Position{0, 0};
  pos_waypoint := Position{10, 1};

  ship := Ship{pos_ship, .East};
  ship2 := Ship{pos_ship, .East};

  ship_waypoint := WayPoint{pos_waypoint, .East, .North};

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case 'A'..'Z':
        scanner.scan(s);
        instr := scanner.token_text(s);
        action := utf8.rune_string_at_pos(instr, 0);
        value := strconv.atoi(instr[1:]);

        switch action {
          case "N":
            move(&ship, value, .North);
            move(&ship_waypoint, value, .North);
          case "S":
            move(&ship, value, .South);
            move(&ship_waypoint, value, .South);
          case "E":
            move(&ship, value, .East);
            move(&ship_waypoint, value, .East);
          case "W":
            move(&ship, value, .West);
            move(&ship_waypoint, value, .West);
          case "L":
            turn_left_ship(&ship, value);
            rotate_ccw(&ship_waypoint, value);
          case "R":
            turn_rigth_ship(&ship, value);
            rotate_cw(&ship_waypoint, value);
          case "F":
            ship2.x += ship_waypoint.x * value;
            ship2.y += ship_waypoint.y * value;
            move(&ship, value, ship.d);
        }
        scanner.next(s);
      case:
        unreachable();
    }
  }

  part1 = abs(ship.x) + abs(ship.y);
  part2 = abs(ship2.x) + abs(ship2.y);

  return;
}

rotate_cw :: proc(using waypoint: ^WayPoint, value: int) {
  // Additional steps required to stay consistent with  `move`

  // Sign correction
  x = value == 90 ? -x : x;

  x = value == 180 ? -x : x;
  y = value == 180 ? -y : y;

  y = value == 270 ? -y : y;

  turn_rigth(&d_x, value);
  turn_rigth(&d_y, value);

  // Keep direction order consistent
  switch d_x {
    case .North, .South:
      d_tmp := d_y;
      d_y = d_x;
      d_x = d_tmp;

      tmp := y;
      y = x;
      x = tmp;
    case .East, .West:
  }
  return;
}

rotate_ccw :: proc(using waypoint: ^WayPoint, value: int) {
  rotate_cw(waypoint, 360 - value);
  return;
}

move :: proc(using pos: ^Position, value: int, direction: Direction) {
  switch direction {
    case .North:
      y += value;
    case .East:
      x += value;
    case .South:
      y -= value;
    case .West:
      x -= value;
  }
  return;
}

turn_left_ship :: proc(using ship: ^Ship, value: int) {
  turn_rigth_ship(ship, 360 - value);
  return;
}

turn_rigth_ship :: proc(using ship: ^Ship, value: int) {
  turn_rigth(&d, value);
  return;
}

turn_rigth :: proc(direction: ^Direction, value: int) {
  switch direction^ {
    case .North:
      direction^ += auto_cast (value / 90);
    case .East:
      direction^ += value == 180 ? auto_cast 2 : auto_cast ((180 - value) / 90);
    case .South:
      direction^ += value == 90 ? auto_cast 1 : auto_cast ((value - 360) / 90);
    case .West:
      direction^ -= auto_cast ((360 - value) / 90);
  }
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
