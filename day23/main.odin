package day23

import "core:fmt"
import "core:strings"
import "core:slice"
import con "core:container"

CUPS_P1 :: 9;
CUPS_P2 :: 1_000_000;

MOVES_P1 :: 100;
MOVES_P2 :: 10_000_000;

Cup :: con.Ring(int);
Cups :: [dynamic]^Cup;

CupTrans :: [CUPS_P2 + 1]int;
Input :: [CUPS_P1]int;

Range :: struct {
  min, max, cnt: int,
}

run_program :: proc(batch: []u8) -> (part1: string, part2: int) {

  cups, range := process_input(batch);
  part1 = run_part1(cups, range);
  part2 = run_part2(batch);
  return;
}

run_part2 :: proc(batch: []u8) -> (res: int) {

  cup_trans: CupTrans;
  input: Input;
  pick_up: [3]int;
  current, destination, after_pick_up: int;

  init_cups(&cup_trans);
  read_input(batch, &input);

  cup_trans[0] = input[0];        // entrypoint
  cup_trans[CUPS_P2] = input[0];  // close the loop

  incorporate_input(&cup_trans, input);
  cup_trans[input[len(input)-1]] = CUPS_P1 + 1;

  for _ in 1..MOVES_P2 {
    current = cup_trans[current];
    destination = current != 1 ? current - 1 : CUPS_P2;

    pick_up[0] = cup_trans[current];
    pick_up[1] = cup_trans[pick_up[0]];
    pick_up[2] = cup_trans[pick_up[1]];

    for slice.contains(pick_up[:], destination) {
      destination = destination != 1 ? destination - 1 : CUPS_P2;
    }

    after_pick_up = cup_trans[pick_up[2]];
    cup_trans[pick_up[2]] = cup_trans[destination];
    cup_trans[destination] = cup_trans[current];
    cup_trans[current] = after_pick_up;
  }

  s1 := cup_trans[1];
  s2 := cup_trans[s1];

  return s1 * s2;
}

run_part1 :: proc(cups: Cups, using range: Range) -> (res: string) {

  // close the loop
  cups[0].prev = cups[cnt-1];
  cups[cnt-1].next = cups[0];

  // init
  current := cups[0];
  pick_up: [3]^Cup;
  destination: ^Cup;

  for _ in 1..MOVES_P1 {
    pick_up = get_new_pick_ups(current);
    destination = find_destination(current, cups, pick_up, range);

    current = label_new_current(current, pick_up);
    process_new_destination(destination, pick_up);
  }

  return collect_labels(current, range);
}

init_cups :: proc(cup_trans: ^CupTrans) {
  for i in 1..<CUPS_P2 do cup_trans[i] = i+1;
}

read_input :: proc(batch: []u8, input: ^Input) {
  for v, i in batch {
    if v != '\n' do input[i] = int(v-'0');
  }
  return;
}

incorporate_input :: proc(cup_trans: ^CupTrans, input: Input) {
  for v, i in input {
    if i == len(input)-1 do return;
    cup_trans[v] = input[i+1];
  }
  return;
}
process_input :: proc(batch: []u8) -> (cups: Cups, range: Range) {

  ring := new(Cup);
  ring = con.ring_init(ring);

  range = Range{9, 0, 0};

  for v in batch {
    if v != '\n' {

      digit := int(v-'0');

      if range.min > digit do range.min = digit;
      if range.max < digit do range.max = digit;
      next := new(Cup);

      ring.value = digit;
      ring.next = next;

      next.prev = ring;
      append(&cups, ring);

      ring = next;
      range.cnt += 1;
    }
  }
  return;
}

label_new_current :: proc(current: ^Cup, pick_up: [3]^Cup) -> (res: ^Cup) {

  res = current.next == pick_up[0] ? pick_up[2].next : current.next;
  current.next = res;
  res.prev = current;

  return;
}

process_new_destination :: proc(destination: ^Cup, pick_up: [3]^Cup) {

  destination_next := destination.next;
  destination.next = pick_up[0];
  pick_up[0].prev = destination;
  destination_next.prev = pick_up[2];
  pick_up[2].next = destination_next;

  return;
}

find_destination :: proc(current: ^Cup, cups: Cups, pick_up: [3]^Cup, using range: Range) -> (destination: ^Cup) {

  destination_label := current.value != 1 ? current.value - 1 : max;

  for _ in 0..<len(pick_up) {
    looper: for r := current.next; r != current; r = r.next {
      for p in pick_up {
        if p.value == destination_label {
          destination_label = destination_label - 1 == min - 1 ? max : destination_label - 1;
          continue looper;
        }
      }
      if r.value == destination_label {
        destination = r;
      }
    }
  }

  return;
}

get_new_pick_ups :: proc(current: ^Cup) -> (pick_up: [3]^Cup) {

  pick_up[0] = current.next;
  pick_up[1] = current.next.next;
  pick_up[2] = current.next.next.next;

  return;
}

find_one :: proc(current: ^Cup) -> (found: ^Cup) {
  r := current;
  for {
    r = r.next;
    if r.value == 1 {
      found = r;
      return;
    }
  }
  return;
}

collect_labels :: proc(current: ^Cup, using range: Range) -> string {
  str_builder: strings.Builder;
  strings.init_builder(&str_builder);

  one := find_one(current);

  for p := one.next; p != one; p = p.next {
    fmt.sbprintf(&str_builder, "%v", p.value);
  }

  return strings.to_string(str_builder);
}

main :: proc() {
  // Load
  batch := #load("input.txt");
  /* batch := #load("input-test.txt"); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
