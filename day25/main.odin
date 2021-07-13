package day25

import "core:fmt"
import "core:strconv"
import "core:strings"

run_program :: proc(batch: string) -> (part1: int) {
  line := strings.split(batch, "\n");
  pk1 := strconv.atoi(line[0]);
  pk2 := strconv.atoi(line[1]);

  value_init := 1;
  part1 = 1;
  subject_number := 7;
  magic_number := 20201227;
  steps: int;

  for {
    steps += 1;
    value_init *= subject_number;
    value_init %= magic_number;
    if pk1 == value_init || pk2 == value_init do break;
  }

  if value_init == pk1 {
    for _ in 1..steps {
      part1 *= pk2;
      part1 %= magic_number;
    }
  } else {
    for _ in 1..steps {
      part1 *= pk1;
      part1 %= magic_number;
    }
  }

  return;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1 := run_program(batch);
  fmt.println("Result part 1:", part1);
}
