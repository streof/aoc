package day06

import "core:fmt"
import "core:strings"

Qs :: bit_set['a'..'z'];

anyone :: proc(batch: []string) -> (acc: int) {
  qs: Qs;
  for i in 0..<len(batch) {
    if batch[i] == "" {
        acc += card(qs);
        qs = {};
        continue;
    }
    for ch in batch[i] {
      switch ch {
        case 'a'..'z':
          incl(&qs, ch);
        case:
      }
    }
  }
  return;
}

everyone :: proc(batch: []string) -> (acc: int) {
  qs_map := make(map[rune]int);
  defer delete(qs_map);
  size: int;

  for i in 0..<len(batch) {
    if batch[i] == "" {
        for l in qs_map {
          acc += qs_map[l] == size ? 1 : 0;
        }
        qs_map = {};
        size = 0;
        continue;
    }
    size += 1;
    for ch in batch[i] {
      switch ch {
        case 'a'..'z':
          qs_map[ch] += 1;
        case:
      }
    }
  }
  return;
}

main :: proc() {
  // Load
  batch := strings.split(string(#load("input.txt")), "\n");

  fmt.println("Result part1:", anyone(batch));
  fmt.println("Result part2:", everyone(batch));
}
