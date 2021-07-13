package day13

import "core:fmt"
import "core:strconv"
import "intrinsics"
import "core:math"
import "core:text/scanner"


run_part1 :: proc(batch: string) -> (res: int) {
  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  time_at_bus_stop : int;
  bus_ids : [dynamic]int;

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case '0'..'9':
        scanner.scan(s);
        tkn := strconv.atoi(scanner.token_text(s));
        if time_at_bus_stop == 0 {
          time_at_bus_stop = tkn;
        } else {
          append(&bus_ids, tkn);
        }
        scanner.next(s);
      case '\n':
        scanner.next(s);
      case ',', 'x':
        scanner.next(s);
      case:
        unreachable();
    }
  }

  next_bus_id : int;
  next_bus_waiting_time : int;

  for i in bus_ids {
    // NOTE: time_at_bus_stop / i is the quotient
    _departure_time := (1 + time_at_bus_stop / i) * i;
    _waiting_time := _departure_time - time_at_bus_stop;

    if next_bus_id == 0 && next_bus_waiting_time == 0 {
      next_bus_waiting_time = _waiting_time;
      next_bus_id = i;
    }

    if _waiting_time < next_bus_waiting_time {
      next_bus_waiting_time = _waiting_time;
      next_bus_id = i;
    }
  }
  return next_bus_id * next_bus_waiting_time;
}

run_part2 :: proc(batch: string) -> (res: int) {
  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  bus_ids : [dynamic]int;
  upper_bound := 1;
  skip := true;

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case '0'..'9':
        scanner.scan(s);
        tkn := strconv.atoi(scanner.token_text(s));
        if skip {
          continue;
        } else {
          append(&bus_ids, tkn);
          upper_bound *= tkn;
        }
        scanner.next(s);
      case '\n':
        skip = false;
        scanner.next(s);
      case 'x':
        append(&bus_ids, -1);
        scanner.next(s);
      case ',':
        scanner.next(s);
      case:
        unreachable();
    }
  }

  // https://en.wikipedia.org/wiki/Chinese_remainder_theorem#Existence_(direct_construction)

  tmp : int;
  for n_i, i in bus_ids {
    a_i := math.floor_mod(-i, n_i);
    if n_i != -1 {
      N_i := upper_bound / n_i;
      M_i, _ := extended_gcd(N_i, n_i);
      tmp += a_i * M_i * N_i;
    }
  }

  return math.floor_mod(tmp, upper_bound);
}

// Follows the pseudocode suggested in https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm

extended_gcd :: proc(x, y: $T) -> (a, b: T)
where intrinsics.type_is_ordered_numeric(T) {
  r_prev := x;
  r      := y;
  s_prev := 1;
  t      := 1;

  s, t_prev, tmp : int;

  for r != 0 {
    quotient := r_prev / r;

    tmp = r;
    r = r_prev - quotient * tmp;
    r_prev = tmp;

    tmp = s;
    s = s_prev - quotient * tmp;
    s_prev = tmp;

    tmp = t;
    t = t_prev - quotient * tmp;
    t_prev = tmp;
  }
  return s_prev, t_prev;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  fmt.println("Result part 1:", run_part1(batch));
  fmt.println("Result part 2:", run_part2(batch));
}
