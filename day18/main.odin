package day18

import "core:fmt"
import "core:text/scanner"
import "core:strconv"
import "core:strings"

Operation :: enum {
  NoOp, // default
  Addition,
  Multiplication,
}

Cursor :: struct {
  operation: Operation,
  bracket_id: int,
  bracket_op: [dynamic]Operation,
  bracket_prev: bool,
  acc_row: [dynamic]int,
  acc: int,
}

part1 :: proc(batch: string) -> (res: int) {
  using scanner, strconv;

  cur := Cursor{operation = .NoOp};
  append(&cur.acc_row, 0);

  scn := Scanner{};
  s := init(&scn, batch);

  for peek(s) != EOF {
    using cur;
    switch peek(s) {
      case '\n':
        assert(len(acc_row) == 1);
        acc += acc_row[0];
        clear(&acc_row);
        append(&acc_row, 0);
        operation = .NoOp;
        next(s);
      case ' ':
        next(s);
      case '(':
        bracket_id += 1;
        bracket_prev = true;
        // if any outstanding
        append(&bracket_op, operation);
        append(&acc_row, 0);
        next(s);
      case ')':
        switch bracket_op[bracket_id-1] {
          case .NoOp, .Addition:
            acc_row[bracket_id-1] += acc_row[bracket_id];
          case .Multiplication:
            if acc_row[bracket_id-1] == 0 do acc_row[bracket_id-1] = 1;
            acc_row[bracket_id-1] *= acc_row[bracket_id];
        }
        pop(&acc_row);
        pop(&bracket_op);
        bracket_id -= 1;
        next(s);
      case '*':
        operation = .Multiplication;
        next(s);
      case '+':
        operation = .Addition;
        next(s);
      case '0'..'9':
        scan(s);
        tkn := atoi(token_text(s));
        switch operation {
          case .NoOp, .Addition:
            acc_row[bracket_id] += tkn;
          case .Multiplication:
            if acc_row[bracket_id] == 0 do acc_row[bracket_id] = 1;
            acc_row[bracket_id] *= tkn;
        }
      case:
        unreachable();
    }
  }

  return cur.acc;
}

part2 :: proc(batch: string) -> (res: int) {
  using scanner, strings;

  scn := Scanner{};
  line := split(batch, "\n");

  for i in 0..<len(line) {
    if line[i] != "" {
      s := init(&scn, line[i]);
      sum := parse_remainder(s);
      res += sum;
    }
  }
  return;
}

Expr :: struct {
  lhs: int,
  rhs: int,
  operation: Operation,
}

eval_expr :: proc(using expr: Expr) -> (res: int) {
  switch operation {
    case .NoOp:
      res = 0;
    case .Addition:
      res = lhs + rhs;
    case .Multiplication:
      res = lhs * rhs;
  }
  return;
}


parse_remainder :: proc(s: ^scanner.Scanner) -> int {
  using scanner, strconv;
  using expr: Expr;

  outer: for {
    switch peek(s) {
      case ' ':
        next(s);
      case '(':
        next(s);
        tmp := parse_remainder(s);
        if operation == .NoOp {
          lhs = tmp;
        } else {
          lhs = eval_expr(Expr{lhs, tmp, operation});
        }
      case ')':
        next(s);
        return lhs;
      case '*':
        operation = .Multiplication;
        next(s);
        // parse and evaluate as * has lower precedence
        rhs = parse_remainder(s);
        return eval_expr(Expr{lhs, rhs, operation});
      case '+':
        operation = .Addition;
        next(s);
      case '0'..'9':
        scan(s);
        tkn := atoi(token_text(s));
        switch operation {
          case .NoOp:
            lhs = tkn;
          case .Addition:
            lhs = eval_expr(Expr{lhs, tkn, operation});
          case .Multiplication:
            // parse and evaluate as * has lower precedence
            rhs = parse_remainder(s);
            lhs = eval_expr(Expr{lhs, rhs, operation});
        }
      case:
        break outer;
    }
}
  return lhs;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));

  fmt.println("Result part 1:", part1(batch));
  fmt.println("Result part 2:", part2(batch));
}
