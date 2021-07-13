package day07

import "core:fmt"
import "core:text/scanner"
import "core:strconv"

outer_to_inner: map[string]Inner;

Inner :: struct {
  colors: [dynamic]string,
  qnt:    [dynamic]int,
  cnt:    int,
}

parse :: proc(batch: string) {

  scan:= scanner.Scanner{};
  s := scanner.init(&scan, batch);

  for scanner.peek_token(s) != scanner.EOF {
    outer := color_text(s);

    scanner.next(s);
    scanner.next(s);

    line: for {
      switch scanner.peek_token(s) {
        case scanner.Int:
          scanner.scan(s);
          qnt := scanner.token_text(s);
          color := color_text(s);

          // take advantage of implicit initialization
          inner, _ := outer_to_inner[outer];
          update(outer, &inner, color, strconv.atoi(qnt));
        case '.':
          scanner.next(s);
          break line;
        case:
          scanner.next(s);
      }
    }
  }
}

part1 :: proc(wanted: string) -> (acc: int) {
  for k, _ in outer_to_inner {
    if k != wanted {
      acc += contains(k, wanted) ? 1 : 0;
    }
  }
  return acc;
}

part2 :: proc(wanted: string) -> (sum: int) {
  sum = calc_sum(wanted);
  return;
}

calc_sum :: proc(wanted: string) -> (sum: int) {
  v, _ := outer_to_inner[wanted];
  for i in 0..<v.cnt {
    sum += v.qnt[i] + v.qnt[i] * calc_sum(v.colors[i]);
  }
  return;
}

contains :: proc(cursor: string, needle: string) -> bool {
  if cursor == needle do return true;
  v, _ := outer_to_inner[cursor];
  for i in 0..<v.cnt {
    if contains(v.colors[i], needle) do return true;
  }
  return false;
}

// see token_text implementation in scanner.odin
color_text :: proc(s: ^scanner.Scanner) -> string {
  scanner.scan(s);
  start := s.tok_pos;
  scanner.scan(s);
  end := s.tok_end;
  return string(s.src[start:end]);
}

update :: proc(outer: string, inner: ^Inner, color: string, qnt: int) {
  append_elem(&inner.colors, color);
  append_elem(&inner.qnt, qnt);
  inner.cnt += 1;
  outer_to_inner[outer] = inner^;
  return;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));

  parse(batch);
  fmt.println("Result part1:", part1("shiny gold"));
  fmt.println("Result part2:", part2("shiny gold"));
}
