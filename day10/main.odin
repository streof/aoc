package day10

import "core:fmt"
import "core:text/scanner"
import "core:strconv"
import "core:slice"
import "core:math"


run_program :: proc(batch: string) -> (part1, part2: int) {
  using scanner;

  num: u8;
  adapters : [dynamic]u8;
  scn := Scanner{};
  s := init(&scn, batch);

  // Scan input
  for peek_token(s) != EOF {
    switch peek_token(s) {
      case Int:
        scan(s);
        num = u8(strconv.atoi(token_text(s)));
        append(&adapters, num);
      case:
        unreachable();
    }
  }

  // PART1
  df1, df3 : int;
  _prev : u8;

  slice.sort(adapters[:]);

  for v, _ in adapters {
    if v - _prev == 1 {
      df1 += 1;
      _prev = v;
    } else if v - _prev == 3 {
      df3 += 1;
      _prev = v;
    } else {
      fmt.printf("Difference can only be 1 or 3; got %d\n", v - _prev);
      break;
    }
  }

  // PART2
  perm_map := make(map[u8]int);
  perm_map[2] = 1;
  perm_map[3] = 2;
  perm_map[4] = 4;
  perm_map[5] = 7;
  perm_map[6] = 13;

  // Get length df1 sequences
  df1_seq : [dynamic]u8;
  _cur_len : u8;
  for i := 0; i < len(adapters); i += 1 {
    if i == 0 && adapters[i] == 1 {
      _cur_len = 1;
      continue;
    }
    if i == len(adapters)-1 {
      if _cur_len == 1 && adapters[i] - adapters[i-1] != 1 {
        append(&df1_seq, _cur_len+1);
      } else {
        append(&df1_seq, _cur_len+2);
      }
    }
    if adapters[i] - adapters[i-1] == 1 do _cur_len += 1;
    if adapters[i] - adapters[i-1] != 1 && i != len(adapters)-1 {
      if _cur_len > 0 {
        append(&df1_seq, _cur_len+1);
        _cur_len = 0;
      }
    }
  }

  // Sanity check df1_seq
  assert(df1 == int(math.sum(df1_seq[:])) - len(df1_seq), "Length df1_seq does not seem to be correct");

  // Calculate #permutations
  perm := 1;
  for i in df1_seq {
    perm *= perm_map[i];
  }

  // account for the builtin adapter (part1 only)
  return df1 * (df3 + 1), perm;
}


main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
