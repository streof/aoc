package day16

import "core:fmt"
import "core:strconv"
import "core:strings"
import m "core:math"
import sl "core:slice"
import con "core:container"

Ranges :: [4]u64;
NUM_FIELDS :: 20;
Fields :: [NUM_FIELDS]int;

part1 :: proc(batch: []string) -> (res: int, my_ticket: [dynamic]int, to_remove_tickets: con.Array(int), mapping : map[string]Ranges, start_nearby: int) {
  using strings, strconv, con;

  cursor, _len, _rnum, _ind_my_ticket : int;
  next : []string;
  ranges : Ranges;
  range_rules := Set{};

  nearby_tickets : Array(int);
  array_init(&nearby_tickets);

  _field, _rest : string;
  for i in 0..<len(batch) {
    if batch[i] == "" {
      cursor += 1;
      continue;
    }
    switch cursor {
      // rules
      case 0:
        _got := split(batch[i], ":");
        _field = _got[0];
        _rest = _got[1];
        rules := split(_rest, " ");
        _rnum = 0; // reset #rules
        for r in rules {
          if contains(r, "-") {
            cur := split(r, "-");
            vl, _ := parse_u64(cur[0]);
            vh, _ := parse_u64(cur[1]);
            ranges[0+_rnum] = vl;
            ranges[1+_rnum] = vh;
            for i in vl..vh {
              set_add(&range_rules, i);
            };
            _rnum += 2;
          };
        }
        mapping[_field] = ranges;

      // my ticket
      case 1:
        if contains(batch[i], "your") {
          _ind_my_ticket = i+1;
        }
        // get next ticket
        next = split(batch[i], ",");

        if _ind_my_ticket == i {
          _my_ticket := sl.mapper(next, atoi);
          for n, _ in _my_ticket {
          append(&my_ticket, n);
          }
        }

      // nearby tickets
      case 2:
        if contains(batch[i], "nearby") {
          start_nearby= i+1;
          continue;
        }

        // get next ticket
        next = split(batch[i], ",");

        if start_nearby == i do _len = len(next);
        assert(_len == len(next));
        nearby_int := sl.mapper(next, atoi);

        for n, _ in nearby_int {
          array_push(&nearby_tickets, n);
        }
    }
  }

  // Check for invalid tickets and compute error rate
  inc: int;
  for n in array_slice(nearby_tickets) {
    if set_not_in(range_rules, u64(n)) {
      array_push(&to_remove_tickets, m.floor_div(inc, _len));
      res += n;
    }
    inc += 1;
  }
  return;
}

part2 :: proc(my_ticket: [dynamic]int, batch: []string, to_remove: con.Array(int), mapping : map[string]Ranges, start: int) -> (res: int) {
  using strings;

  _to_remove := con.array_slice(to_remove);
  field_cnt := make(map[string]Fields);

  num_tickets : int;
  for i in start..<len(batch) {
    if batch[i] != "" {
      if sl.contains(_to_remove, i-start) {
        continue;
      };
      num_tickets += 1;
      ticket := split(batch[i], ",");
      process_ticket(ticket, mapping, &field_cnt);
    }
  }

  field_poss := make(map[string]Fields);
  assigned := make(map[string]int);

  init(&field_poss, &field_cnt, &assigned, num_tickets);
  reduce(&field_poss, &assigned);

  departure_fields := make([dynamic]int);
  for k, v in assigned {
    if strings.contains(k, "departure") {
      append(&departure_fields, v);
    }
  }

  res = 1;
  for i in departure_fields {
    res *= my_ticket[i];
  }

  return;
}

process_ticket :: proc(ticket: []string, mapping: map[string]Ranges, field_cnt: ^map[string]Fields) {
  using strconv;

  for n, ind in ticket {
    for k, _ in mapping {
      n, _ := parse_u64(n);
      // update map
      if (mapping[k][0] <= n && mapping[k][1] >= n) || (mapping[k][2] <= n && mapping[k][3] >= n) {
        fk := field_cnt[k];
        fk[ind] += 1;
        field_cnt[k] = fk;
      }
    }
  }
  return;
}

init :: proc(field_poss: ^map[string]Fields, field_cnt: ^map[string]Fields, assigned: ^map[string]int, num_tickets: int) {

  for k, _ in field_cnt {
    assigned[k] = -1;
    for n, i in field_cnt[k] {
      if n == num_tickets {
        fk := field_poss[k];
        fk[i] = 1;
        field_poss[k] = fk;
      }
    }
  }
  return;
}

reduce :: proc(field_poss: ^map[string]Fields, assigned: ^map[string]int) {

  to_sub := false;
  unassigned := true;
  for k, v in field_poss {
    // if there is only 1 possibility for a given field we store its index and substract it from all other fields
    if m.sum(v[:]) == 1 {
      ind, _ := sl.linear_search(v[:], 1);
      if assigned[k] != -1 {
        unassigned = false;
        continue;
      } else {
        assigned[k] = ind;
        to_sub = true;
      }
    }
    for to_sub {
      for kk, vv in field_poss {
        if kk != k do vv -= v;
      }
      to_sub = false;
    }
  }

  for unassigned {
    reduce(field_poss, assigned);
    unassigned = any_unassigned(assigned^);
  }

  return;
}

any_unassigned :: proc(x: map[string]int) -> (out: bool) {
  for _, v in x {
    if v == -1 {
      return true;
    }
  }
  return false;
}

main :: proc() {
  // Load
  batch := strings.split(string(#load("input.txt")), "\n");

  part1, my_ticket, to_remove, mapping, start := part1(batch);
  part2 := part2(my_ticket, batch, to_remove, mapping, start);

  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
