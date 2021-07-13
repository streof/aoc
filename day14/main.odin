package day14

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strconv"
import "core:text/scanner"


Address :: struct {
  value: u64,
}

Memory :: map[u64]^Address;

run_program :: proc(batch: string) -> (part1: u64, part2: u64) {
  using scanner;

  got_mask: bool;

  scn := Scanner{};
  s := init(&scn, batch);

  memory_map, memory_map2 : Memory;

  // Custom allocation for storing the memory addresses
  buf: [16 * 1024]byte;
  a: mem.Arena;
  mem.init_arena(&a, buf[:]);
  val, _adr : u64;
  bitmask : string;

  allocator := mem.arena_allocator(&a);
  defer delete(buf[:], allocator);

  adr := new_clone(Address{}, allocator);
  adr2 := new_clone(Address{}, allocator);

  for peek(s) != EOF {
    switch peek(s) {
      case 'a'..'z':
        scan(s);
        ch := token_text(s);
        if ch == "mask" {
          got_mask = true;
        } else {
          scan(s);
          ch = token_text(s);
          if ch == "[" {
            scan(s);
            ch = token_text(s);
            val, _ = strconv.parse_u64(ch);
            adr = new_clone(Address{}, allocator);
            memory_map[val] = adr;

            // part 2: address -> bitmask -> intermediate representation -> addresses
            base_arr : [dynamic]u64;
            defer delete(base_arr);

            _adr = val;
            base, indices := convert_to_ir(_adr, bitmask);
            append(&base_arr, base);
            ir_to_address(&base_arr, &indices);

            // Assign current value to derived memory addresses
            adr2 = new_clone(Address{}, allocator);
            for bs in base_arr {
              memory_map2[bs] = adr2;
            }
            next(s);
          }
        }
        next(s);
      case '=':
        scan(s);
        if got_mask {
          scan(s);
          bitmask = get_bitmask(s);
          got_mask = false;
          next(s);
        } else {
          scan(s);
          tkn := token_text(s);
          // apply bitmask
          _val, _ := strconv.parse_u64(tkn);
          adr.value = apply_bitmask(_val, bitmask);
          // part 2 (no need to apply bitmask to value)
          adr2.value = _val;
          next(s);
        }
      case:
        next(s);
    }
  }

  // part 1
  for _, v in memory_map {
    part1 += v.value;
  }

  // part 2
  for _, v in memory_map2 {
    part2 += v.value;
  }

  return;
}

ir_to_address :: proc(addresses: ^[dynamic]u64, indices: ^[dynamic]int) {

  if len(indices) == 0 do return;

  _adr : u64;
  for idx in indices {
    for adr in addresses {
      _adr = adr;
      _adr ~= 1 << uint(36 - idx - 1);    // toggling 'ind' bit
      if slice.contains(addresses[:], _adr) {
        continue;
      } else {
        append(addresses, _adr);
      }
    }
    _, ok := pop_front_safe(indices); if ok {
      ir_to_address(addresses, indices);
    }
  }
  return;
}

convert_to_ir :: proc(address: u64, bitmask: string) -> (base: u64, indices: [dynamic]int) {
  base = address;
  for bit, ind in bitmask {
    switch bit {
      case 'X':
        append(&indices, ind);
      case '1':
        base |= 1 << uint(len(bitmask) - ind - 1);    // setting 'ind' bit
      case '0':
        continue;
    }
  }
  return;
}

apply_bitmask :: proc(value: u64, bitmask: string) -> u64 {
  val := value;

  for bit, ind in bitmask {
    switch bit {
      case 'X':
        continue;
      case '1':
        val |= 1 << uint(len(bitmask) - ind - 1);    // setting bit
      case '0':
        val &~= 1 << uint(len(bitmask) - ind - 1);   // cleaning bit
    }
  }
  return val;
}

get_bitmask :: proc(s: ^scanner.Scanner) -> string {
  start := s.tok_pos;
  end := s.tok_pos + 36;  // fixed length bitmask
  return string(s.src[start:end]);
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
