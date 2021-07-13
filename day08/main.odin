package day08

import "core:fmt"
import "core:strings"
import "core:reflect"
import "core:strconv"

ACCUMULATOR: int;

InstructionType :: enum {
  nop,
  acc,
  jmp,
}

part1 :: proc(batch: []string) -> (res: int) {
  using strconv, strings;

  visited : [650]bool;
  seq: []string;
  instr: string;
  value, line: int;

  for {
    seq = split(batch[line], " ");

    if visited[line] {
      res = ACCUMULATOR;
      visited = {};
      break;
    }

    visited[line] = true;
    instr = seq[0];
    value = atoi(seq[1]);

    instr_type, ok := reflect.enum_from_name(InstructionType, instr);
    assert(ok);

    switch instr_type {
      case .nop:
        line += 1;
      case .acc:
        ACCUMULATOR += value;
        line += 1;
      case .jmp:
        line += value;
    }
  }
  return;
}

part2 :: proc(batch: []string) -> (res: int) {
  using strconv, strings;

  visited : [650]bool;
  seq: []string;
  instr: string;
  value, line, line_swapped: int;
  _LEN := len(batch) - 1; // exclude EOF line

  outer: for line_swapped != len(batch) {
    inner: for {
      seq = split(batch[line], " ");

      if visited[line] {
        ACCUMULATOR = 0;
        visited = {};
        line = 0;
        line_swapped += 1;
        break inner;
      }

      visited[line] = true;
      instr = seq[0];
      value = atoi(seq[1]);

      instr_type, ok := reflect.enum_from_name(InstructionType, instr);
      assert(ok);

      switch instr_type {
        case .nop:
          if line == line_swapped {
            line += value;
          } else {
            line += 1;
          }
        case .acc:
          if line == line_swapped {
            break inner; // acc instructions are not corrupted
          }
          ACCUMULATOR += value;
          line += 1;
        case .jmp:
          if line != line_swapped {
            line += value;
          } else {
            line += 1;
          }
      }

      if line == _LEN {
        res = ACCUMULATOR;
        break outer;
      }
    }
  }
  return;
}


main :: proc() {
  // Load
  batch := strings.split(string(#load("input.txt")), "\n");

  fmt.println("Result part 1:", part1(batch));
  fmt.println("Result part 2:", part2(batch));
}
