package day01

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:container"

part1 :: proc() -> u64 {
  using strconv, container;

  // Read
  data, success := os.read_entire_file("input.txt");
  if !success {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Parse
  lines := strings.split(string(data), "\n");
  set, prod := Set{}, u64(0);

  for line in lines {
    x, ok := parse_u64(line);
    if ok {
      set_add(&set, x);
    }

    // Check
    rem := 2020 - x;
    if set_in(set, rem) {
      prod = x * rem;
      defer set_clear(&set);
      break;
    }
  }
  return prod;
}

part2 :: proc() -> u64 {
  using strconv, container;

  // Read
  data, success := os.read_entire_file("input.txt");
  if !success {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Parse
  lines := strings.split(string(data), "\n");
  ln := len(lines);
  set, prod := Set{}, u64(0);

  outer:
  for i in 0..<ln {
    x, ok := parse_u64(lines[i]);
    if ok {
      set_add(&set, x);
    }
    for j in 0..<ln-1 {
      y, _:= parse_u64(lines[j]);

      // Check
      rem := 2020 - x - y;
      if set_in(set, rem) {
        prod = x * y * rem;
        defer set_clear(&set);
        break outer;
      }
    }
  }
  return prod;
}

main :: proc() {
  fmt.println("Result part1:", part1());
  fmt.println("Result part2:", part2());
}
