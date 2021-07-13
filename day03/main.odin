package day03

import "core:fmt"
import "core:os"
import "core:strings"

part1 :: proc() -> int {
  // Read
  data, ok := os.read_entire_file("input.txt");
  if !ok {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Parse
  lines := strings.split(string(data), "\n");
  return count_trees(lines, 3, 1);
}

part2 :: proc() -> int {
  // Read
  data, ok := os.read_entire_file("input.txt");
  if !ok {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Parse
  lines := strings.split(string(data), "\n");
  w11 := count_trees(lines, 1, 1);
  w31 := count_trees(lines, 3, 1);
  w51 := count_trees(lines, 5, 1);
  w71 := count_trees(lines, 7, 1);
  w12 := count_trees(lines, 1, 2);
  prod:= w11 * w31 * w51 * w71 * w12;
  return prod;
}

count_trees :: proc(lines: []string, dx: int, dy: int) -> (trees: int) {
  // Init
  width := len(lines[0]);
  height := len(lines) - 1; // last line is EOF
  y, x: int;

  for y < height {
    if lines[y][x%width] == '#' do trees +=1;
    y += dy;
    x += dx;
  }
  return trees;
}

main :: proc() {
  fmt.println("Result part1:", part1());
  fmt.println("Result part2:", part2());
}
