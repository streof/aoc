package day21

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:text/scanner"

Ingredients :: [dynamic]string;
FoodIds :: [dynamic]u8;

DecodedAllergenName :: string;

AllergenInfo :: struct {
  food_ids : FoodIds,
}

run_program :: proc(batch: string) -> (part1: int, part2: string) {
  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  _key : u8;
  scanning_allergens : bool;
  food_map : map[u8]Ingredients;
  allergens_map : map[DecodedAllergenName]AllergenInfo;
  ingredients_map : map[string]FoodIds;

  food_map[_key] = make_dynamic_array(Ingredients);

  for scanner.peek(s) != scanner.EOF {
    switch scanner.peek(s) {
      case '(':
        scanning_allergens = true;
        scanner.next(s);
      case ')':
        scanning_allergens = false;
        scanner.next(s);
      case:
        scanner.scan(s);
        tkn := scanner.token_text(s);
        if tkn != "contains" {
          if !scanning_allergens {
            if len(ingredients_map[tkn]) == 0 {
              tmp := make_dynamic_array(FoodIds);
              ingredients_map[tkn] = tmp;
            }
            append(&food_map[_key], tkn);
            append(&ingredients_map[tkn], _key);
          } else {
            if tkn in allergens_map {
              tmp := allergens_map[tkn];
              append(&tmp.food_ids, _key);
              allergens_map[tkn] = tmp;
            } else {
              food_ids := make_dynamic_array(FoodIds);
              append(&food_ids, _key);
              allergen_info := AllergenInfo{food_ids};
              allergens_map[tkn] = allergen_info;
            }
          }
        }
        scanner.next(s);
      case '\n':
        if scanner.peek_token(s) != scanner.EOF {
          _key += 1;
          _val := make_dynamic_array(Ingredients);
          food_map[_key] = _val;
          scanning_allergens = false;
        }
        scanner.next(s);
    }
  }

  // For each allergen
  //  1) make a list of its possible translations
  //  2) use recursion to derive the only possible translation
  //  3) create a list with all encoded and one with all decoded names

  candidates : map[string]Ingredients;
  allergens_encoded, allergens_decoded: Ingredients;

  for k, info in allergens_map {
    _food_ids := info.food_ids;
    for name, range in ingredients_map {
      if is_subslice(range, _food_ids) {
        if len(candidates[k]) == 0 {
          tmp := make_dynamic_array(Ingredients);
          candidates[k] = tmp;
        }
        append(&candidates[k], name);
      }
    }
  }

  derive_matches(&candidates);

  for k, v in candidates {
    append(&allergens_encoded, v[0]);
    append(&allergens_decoded, k);
  }

  // PART1
  for _, v in food_map {
    for vv in v {
      if !slice.contains(allergens_encoded[:], vv) do part1 += 1;
    }
  }

  // PART2
  slice.sort(allergens_decoded[:]);

  allergens_encoded_sorted : Ingredients;
  for k in allergens_decoded {
    append(&allergens_encoded_sorted, candidates[k][0]);
  }

	str_builder: strings.Builder;
	strings.init_builder(&str_builder);

  for v, i in allergens_encoded_sorted {
    if i == len(allergens_encoded_sorted)-1 {
      fmt.sbprintf(&str_builder, "%v", v);
    } else {
      fmt.sbprintf(&str_builder, "%v,", v);
    }
  }

  part2 = strings.to_string(str_builder);

  return;
}

derive_matches :: proc(candidates: ^map[string]Ingredients) {
  cnt : int;
  for _, v in candidates {
    cnt += len(v) == 1 ? 1 : 0;
  }
  if cnt == len(candidates) do return;

  for k, v in candidates {
    for kk, vv in candidates {
      if len(v) == 1 && k != kk {
        _ind, _found := slice.linear_search(vv[:], v[0]);
        if _found {
          ordered_remove(&candidates[kk], _ind);
          derive_matches(candidates);
        }
      }
    }
  }
}

is_subslice :: proc(a, b: FoodIds) -> (res: bool) {
  for x in b {
    if !slice.contains(a[:], x) do return false;
  }
  return true;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
