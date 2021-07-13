package day05

import "core:fmt"
import "core:strings"
import "core:strconv"

process :: proc(batch: []string) -> (seats: [1024]u64)  {
  using strings, strconv;

  for line in batch {
    if line == "" do break;
    row:= "";
    for ch in line {
      switch ch {
        case 'B', 'R':
          row = concatenate({row, "1"});
        case 'F', 'L':
          row = concatenate({row, "0"});
      }
    }
    // * 8 (i.e. 1000) is the same as adding 000 at the end
    // therefore: row * 8 + column = row + column (in binary)
    pass := concatenate({row[:7], row[7:]});
    v, _ := parse_u64_of_base(pass, 2);
    seats[v] = v;
  }
  return;
}

main :: proc() {
  // Load
  batch := strings.split(string(#load("input.txt")), "\n");

  seats := process(batch);
  cnt: [dynamic]int;

  for i in 0..<len(seats) {
    if (seats[i] != 0) && (seats[i+1] == 0) {
      append_elem(&cnt, i);
    }
  }

  fmt.println("Result part1:", cnt[1]);
  fmt.println("Result part2:", cnt[0]+1);
}
