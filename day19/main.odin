package day19

import "core:fmt"
import "core:text/scanner"
import "core:strconv"
import "core:strings"
import "core:mem"
import "core:slice"
import "core:unicode/utf8"


Rules :: [dynamic]u8;

Letter :: string;

Value :: union {
  [dynamic]Rules,
  Letter,
}

Lookup :: struct {
  values: Value,
}

Dict :: map[u8]^Lookup; // rule_id |-> rules


count_matches :: proc(batch: string) -> (part1, part2: int) {
  using scanner, strings;

  scn := Scanner{};
  s := init(&scn, batch);

  dict := Dict{};

  // Custom allocation for storing values of map keys
  buf: [8192]byte;
  a: mem.Arena;
  mem.init_arena(&a, buf[:]);

  allocator := mem.arena_allocator(&a);
  defer delete(buf[:], allocator);

  // fill out dict
  parse_rules(s, &dict, allocator);

  // prepare rules for part2
  new_rules := prep_part2(allocator);

  // search for messages that match rule_id = 0!
  for peek(s) != EOF {
    switch peek(s) {
      case 'a'..'z':
        scan(s);
        _msg := token_text(s);
        _tmp := make_dynamic_array([dynamic]u8);
        defer delete(_tmp);
        append(&_tmp, 0); // rule_id = 0

        // Part1
        if check_message(dict, _msg, _tmp) {
          part1 += 1;
        };

        // Part2
        update_dict(&dict, new_rules);
        if check_message(dict, _msg, _tmp) {
          part2 += 1;
        };
        restore_dict(&dict);

        next(s);
      case:
        next(s);
    }
  }
  return;
}

check_message :: proc(dict: Dict, msg: string, rule_ids: [dynamic]u8) -> bool {
  if len(rule_ids) == 0 do return false;

  // Iterate over the rules from dict
  current, remaining := slice.split_first(rule_ids[:]);
  switch v in dict[current].values {
    case Letter:
      if v == utf8.rune_string_at_pos(msg, 0) {
        // We've got a match so we can shift our message and rules (i.e. `remaining`) by 1 position
        _msg := msg[1:];
        if len(_msg) == 0 && len(remaining) == 0 do return true;
        return check_message(dict, _msg, slice.to_dynamic(remaining));
      };
      return false;
    case [dynamic]Rules:
      // Iterate over nested rules (regex groups)
      for vv in v {
        // NOTE: Include remaining rules during each iteration
        _concat := slice.concatenate([][]u8{vv[:], remaining});
        if check_message(dict, msg, slice.to_dynamic(_concat)) do return true;
      }
  }
  return false;
}

parse_rules :: proc(s: ^scanner.Scanner, dict: ^Dict, allocator: mem.Allocator) {
  using scanner, strings;

  _key, num : u8;
  _lookup := new_clone(Lookup{}, allocator);

  _rules := make([dynamic]u8);
  _values := make([dynamic]Rules);
  defer delete(_rules);
  defer delete(_values);

  rules: for peek_token(s) != EOF {
    switch peek_token(s) {
      case Int:
        scan(s);
        num = u8(strconv.atoi(token_text(s)));

        switch peek(s) {
          case ':':
            if _, ok := dict[num]; ok {
              panic("Rule id should be unique");
            }
            // Init lookup for new key
            _key = num;
            _lookup = new_clone(Lookup{}, allocator);
            dict[_key] = _lookup;
          case:
            append(&_rules, u8(num));
          case '\n':
            // Store previous rules map
            _, ok := _lookup.values.(Letter); if !ok {
              append(&_rules, u8(num));
              append(&_values, _rules);
              _lookup.values = _values;
            }

            // Re-init for next key
            _rules = make_dynamic_array([dynamic]u8);
            _values = make_dynamic_array([dynamic]Rules);
        }
        next(s);
      case '|':
        append(&_values, _rules);
        _rules = make_dynamic_array([dynamic]u8);
        next(s);
      case String:
        scan(s);
        ch, ok := unquote_ascii(token_text(s));
        assert(ok, "Got an invalid quoted character");
        _lookup.values = ch;
        next(s);
      case Ident:
        break rules;
      case:
        unreachable();
    }
  }
  return;
};

prep_part2 :: proc(allocator: mem.Allocator) -> (res: [2][dynamic]u8) {
  new_rules_8 := make_dynamic_array_len_cap([dynamic]u8, 0, 2, allocator);
  new_rules_11 := make_dynamic_array_len_cap([dynamic]u8, 0, 3, allocator);
  append(&new_rules_8, 42, 8);
  append(&new_rules_11, 42, 11, 31);
  res[0] = new_rules_8;
  res[1] = new_rules_11;
  return;
}

update_dict :: proc(dict: ^Dict, values: [2][dynamic]u8) {
  update_dict_entries(dict, 8, values[0]);
  update_dict_entries(dict, 11, values[1]);
  return;
}

restore_dict :: proc(dict: ^Dict) {
  restore_dict_entries(dict, 8);
  restore_dict_entries(dict, 11);
}

restore_dict_entries :: proc(dict: ^Dict, key: u8) {
  v := dict[key].values.([dynamic]Rules);
  pop(&v);
  dict[key].values = v;
  return;
}

update_dict_entries :: proc(dict: ^Dict, key: u8, value: [dynamic]u8) {
  v := dict[key].values.([dynamic]Rules);
  append(&v, value);
  dict[key].values = v;
  return;
}

unquote_ascii :: proc(ch: string) -> (un: string, success: bool) {
  if len(ch) != 3 || ch[0] != '"' || ch[2] != '"' {
    return ch, false;
  }
  return utf8.rune_string_at_pos(ch, 1), true;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */
  part1, part2 := count_matches(batch);

  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
