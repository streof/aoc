package day09

import "core:fmt"
import "core:text/scanner"
import "core:container"
import "core:strconv"
import "core:math"
import "core:slice"

PREAMBLE :: 25;

part1 :: proc(batch: string) -> (res: int) {
  using scanner, container, strconv;

  scn := Scanner{};
  s := init(&scn, batch);

  window : Array(int);
  array_init(&window);

  inc: int;
  for peek_token(s) != EOF {
    switch peek_token(s) {
      case '\n':
        next(s);
      case Int:
        scan(s);
        num := atoi(token_text(s));

        // fill out preamble first
        if inc < PREAMBLE {
          array_push_back(&window, num);
          inc += 1;
        } else {
          preamble := array_slice(window);
          found := false;
          outer: for a in preamble {
            for b in preamble {
              res = num - a;
              if b == res && b != a {
                found = true;
                array_push_back(&window, num);
                array_pop_front(&window);
                break outer;
              }
            }
          }
          if !found do return num;
        }
        next(s);
      case:
        unreachable();
    }
  }
  return;
}


part2 :: proc(batch: string) -> (res: int) {
  using scanner, container, strconv, math;

  got := part1(batch);

  scn := Scanner{};
  s := init(&scn, batch);

  window : Array(int);
  array_init(&window);

  len: int;
  for peek_token(s) != EOF {
    switch peek_token(s) {
      case '\n':
        next(s);
      case Int:
        scan(s);
        num := atoi(token_text(s));
        len += 1;
        array_push_back(&window, num);
        for _ in 1..len {
          window_slice := array_slice(window);
          _sum := sum(window_slice);

          if _sum == got {
            slice.sort(window_slice);
            _min := window_slice[0];
            _max := window_slice[window.len-1];
            return _min + _max;
          }
          for _sum > got {
            array_pop_front(&window);
            len -= 1;
            window_slice = array_slice(window);
            _sum = sum(window_slice);

            if _sum == got {
              slice.sort(window_slice);
              _min := window_slice[0];
              _max := window_slice[window.len-1];
              return _min + _max;
            }
          }
        }
        next(s);
      case:
        unreachable();
    }
  }
  return;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));

  fmt.println("Result part 1:", part1(batch));
  fmt.println("Result part 2:", part2(batch));
}
