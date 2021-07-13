// NOTE: this is a VERY ineffecient implementation. Compiling in release mode is
// probably a good idea :)
package day15

import "core:fmt"
import "core:strconv"
import "core:strings"
import sl "core:slice"

Span :: [2]int;

NUMBER_OF_TURNS_P1 :: 2020;
NUMBER_OF_TURNS_P2 :: 30000000;

part1 :: proc(batch: string) -> int {
  using strings, strconv;

  starting_numbers := split(batch, ",");

  turns : [NUMBER_OF_TURNS_P1]int;
  turns = -1;
  next_turn_index : int;

  // populate first turns with starting numbers (backwards)
  for i in 0..<len(starting_numbers) {
    if starting_numbers[i] != "" {
      num := atoi(starting_numbers[i]);
      turns[NUMBER_OF_TURNS_P1-1-i] = num;
      next_turn_index += 1;
    }
  }

  // loop over remaining turns
  for i := NUMBER_OF_TURNS_P1-1-next_turn_index; i >= 0; i -= 1 {
    _last_spoken := turns[i+1];

    _index, _found := sl.linear_search(turns[i+2:], _last_spoken);
    if _found {
      turns[i] = _index+1;
    } else {
      turns[i] = 0;
    }
  }

  return turns[0];
}

part2 :: proc(batch: string) -> (res: int) {
  using strings, strconv;

  starting_numbers := split(batch, ",");

  span : map[int]Span; // map: number |-> [end, start]
  last_spoken, turn : int;

  // populate first turns with starting numbers
  for i in 0..<len(starting_numbers) {
    if starting_numbers[i] != "" {
      last_spoken = atoi(starting_numbers[i]);
      turn = i+1;
      span[last_spoken] = Span{turn, 0};
    }
  }

  // loop over remaining turns
  _tmp : int;
  for i in turn+1..NUMBER_OF_TURNS_P2 {

    // Determine new value `last_spoken`
    if span[last_spoken][1] == 0 {
      last_spoken = 0;
    } else {
      last_spoken = span[last_spoken][1] - span[last_spoken][0];
    }

    // Update span `last_spoken`
    if (span[last_spoken] == Span{0, 0}) {
      span[last_spoken] = Span{i, 0};
    } else if span[last_spoken][1] == 0 {
      _tmp = span[last_spoken][0];
      span[last_spoken] = Span{_tmp, i};
    } else {
      _tmp = span[last_spoken][1];
      span[last_spoken] = Span{_tmp, i};
    }
  }

  return last_spoken;
}


main :: proc() {
  // Load
  batch := string(#load("input.txt"));

  fmt.println("Result part 1:", part1(batch));
  fmt.println("Result part 2:", part2(batch));
}
