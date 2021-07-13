package day02

import "core:fmt"
import "core:os"
import "core:text/scanner"
import "core:strconv"

parse :: proc(s: ^scanner.Scanner) -> (min: int, max: int, char: rune, pass: string) {
  using strconv;
  token: rune;

  // Get min
  if scanner.peek(s) != scanner.EOF {
    token = scanner.scan(s);
    assert(token == scanner.Int);
    min = atoi(scanner.token_text(s));
    scanner.next(s);

    // Get max
    token = scanner.scan(s);
    assert(token == scanner.Int);
    max = atoi(scanner.token_text(s));
    scanner.next(s);

    // Get character
    char = scanner.next(s);
    scanner.next(s);
    scanner.next(s);

    // Get password
    token = scanner.scan(s);
    assert(token == scanner.Ident);
    pass = scanner.token_text(s);
  }
  return;
}

is_valid :: proc(min: int, max: int, char: rune, pass: string) -> int {
  count: int;
  for s in pass {
    if s == char do count += 1;
  }
  return (min <= count) & (max >= count) ? 1 : 0;
}

is_valid_pos :: proc(min: int, max: int, char: rune, pass: string) -> bool {
  position: int = 1;
  valid: bool;
  for s in pass {
    if s == char {
      valid ~= position == min || position == max;
    }
    position += 1;
  }
  return valid;
}

part1 :: proc() -> int {
  // Read
  data, ok := os.read_entire_file("input.txt");
  if !ok {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Scan
  scan:= scanner.Scanner{};
  scanner.init(&scan, string(data));
  cnt:= 0;

  for {
    if scanner.peek(&scan) == '\n' do scanner.next(&scan);
    if scanner.peek(&scan) == scanner.EOF do break;
    cnt += is_valid(parse(&scan));
  }
  return cnt;
}

part2 :: proc() -> int {
  // Read
  data, ok := os.read_entire_file("input.txt");
  if !ok {
    fmt.printf("File not found");
    os.exit(1);
  }
  defer delete(data);

  // Scan
  scan:= scanner.Scanner{};
  scanner.init(&scan, string(data));
  cnt:= 0;

  for {
    if scanner.peek(&scan) == '\n' do scanner.next(&scan);
    if scanner.peek(&scan) == scanner.EOF do break;
    if is_valid_pos(parse(&scan)) do cnt += 1;
  }
  return cnt;
}

main :: proc() {
  fmt.println("Result part1:", part1());
  fmt.println("Result part2:", part2());
}
