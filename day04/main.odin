package day04

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:reflect"

Field :: enum {
  byr,
  iyr,
  eyr,
  hgt,
  hcl,
  ecl,
  pid,
  cid,
};

Fields_Set :: bit_set[Field];
Fields_Set_Required := ~Fields_Set{} &~ {.cid};

Passport :: struct {
  fields: Fields_Set,
  kv: map[Field]string,
}

valid_part2 :: proc(kv: map[Field]string) -> bool {
  using strconv;
  cnt: int;

  for k, v in kv {

    #partial switch k {
      case .byr:
        cnt += 1920 <= atoi(v) && atoi(v) <= 2002 ? 1 : 0;
      case .iyr:
        cnt += 2010 <= atoi(v) && atoi(v) <= 2020 ? 1 : 0;
      case .eyr:
        cnt += 2020 <= atoi(v) && atoi(v) <= 2030 ? 1 : 0;
      case .hgt:
        unit := v[len(v)-2:];
        quan := v[:len(v)-2];
        switch unit {
          case "cm":
            cnt += 150 <= atoi(quan) && atoi(quan) <= 193 ? 1 : 0;
          case "in":
            cnt += 59 <= atoi(quan) && atoi(quan) <= 76 ? 1 : 0;
        }
      case .hcl:
        if v[0] != 35 || len(v) != 7 do break;
        cnt += 1;
        for ch in v[1:] {
          switch ch {
            case '0'..'9', 'a'..'f':
            case: cnt -= 1; break;
          }
        };
      case .ecl:
        switch v {
          case "amb", "blu", "brn", "gry", "grn", "hzl", "oth":
            cnt += 1;
        }
      case .pid:
        if len(v) != 9 do break;
        cnt += 1;
        for ch in v {
          switch ch {
            case '0'..'9':
            case: cnt -= 1; break;
          }
        }
    }
  }
  return cnt == 7;
}

num_valid :: proc(batch: []string) -> (part1: int, part2: int) {
  using strings;

  seq: []string;
  passport: Passport;

  // Parse
  for line in 0..<len(batch) {
    seq = split(batch[line], " ");
    for pair in seq {

      // If newline / EOF, chech if current passport is valid
      if pair == "" {

        part1 += Fields_Set_Required <= passport.fields ? 1 : 0;
        part2 += valid_part2(passport.kv) ? 1 : 0;

        passport = Passport{};
        break;
      }

      // Get key-value pairs
      kv : []string = split(pair, ":");
      key := kv[0];
      val := kv[1];
      key_enum, ok := reflect.enum_from_name(Field, key); assert(ok);

      // Add to current passport
      incl(&passport.fields, key_enum);
      passport.kv[key_enum] = val;
    }
  }
  return;
}

main :: proc() {
  // Load
  batch := strings.split(string(#load("input.txt")), "\n");

  // Calculate number valid passports
  part1, part2 := num_valid(batch);
  fmt.println("Result part1:", part1);
  fmt.println("Result part2:", part2);
}
