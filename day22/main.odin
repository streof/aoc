package day22

import "core:fmt"
import "core:text/scanner"
import "core:strconv"
import "core:slice"

Deck :: [dynamic]int;
GameState :: [2]Deck;

run_program :: proc(batch: string) -> (part1, part2: int) {
  scn := scanner.Scanner{};
  s := scanner.init(&scn, batch);

  reading_cards : bool;
  current_player : int;
  game_state : GameState;

  for scanner.peek_token(s) != scanner.EOF {
    switch scanner.peek_token(s) {
      case scanner.Int:
        scanner.scan(s);
        tkn := scanner.token_text(s);
        num := strconv.atoi(tkn);
        if scanner.peek(s) == '\n' {
          reading_cards = true;
        } else {
          reading_cards = false;
          current_player = num -1;
        }
        if reading_cards {
          if len(game_state[current_player]) == 0 {
            tmp := make_dynamic_array(Deck);
            append(&tmp, num);
            game_state[current_player] = tmp;
          } else {
            append(&game_state[current_player], num);
          }
        }
        scanner.next(s);
      case:
        scanner.next(s);
    }
  }

  // Prep part 2
  game_state_copy := copy_game_state(game_state, 0, 0);

  // PART1
  winner := regular_combat(&game_state);

  size_deck := len(game_state[winner]);
  for i in 1..size_deck {
    part1 += pop(&game_state[winner]) * i;
  }

  // PART2
  history : [dynamic]GameState;
  winner2 := recursive_combat(&game_state_copy, &history);

  size_deck2 := len(game_state_copy[winner2]);
  for i in 1..size_deck2 {
    part2 += pop(&game_state_copy[winner2]) * i;
  }

  return;
}

recursive_combat :: proc(game_state: ^GameState, history: ^[dynamic]GameState) -> (winner: int) {

  for len(game_state[0]) != 0 && len(game_state[1]) != 0 {

    for games in history {
      if slice.equal(games[0][:], game_state[0][:]) &&
      slice.equal(games[1][:], game_state[1][:]) {
        return 0;
      }
    }

    // Add to history before popping
    game_state_current := copy_game_state(game_state^, 0, 0);
    append(history, game_state_current);

    card_player1 := pop_front(&game_state[0]);
    card_player2 := pop_front(&game_state[1]);

    size_deck_player1 := len(game_state[0]);
    size_deck_player2 := len(game_state[1]);

    if size_deck_player1 >= card_player1 && size_deck_player2 >= card_player2 {

      game_state_sub := copy_game_state(game_state^, card_player1, card_player2);

      if regular_combat(&game_state_sub) == 0 {
        append(&game_state[0], card_player1, card_player2);
        return 0;
      } else {
        append(&game_state[1], card_player2, card_player1);
        return 1;
      }
    } else if card_player1 > card_player2 {
      append(&game_state[0], card_player1, card_player2);
      recursive_combat(game_state, history);
    } else {
      append(&game_state[1], card_player2, card_player1);
      recursive_combat(game_state, history);
    }
  }

  return len(game_state[0]) == 0 ? 1 : 0;
}

copy_game_state :: proc(gs_init: GameState, max_cnt_p1, max_cnt_p2: int) -> (gs: GameState) {
  if max_cnt_p1 == 0 && max_cnt_p2 == 0 {
    gs[0] = slice.to_dynamic(gs_init[0][:]);
    gs[1] = slice.to_dynamic(gs_init[1][:]);
    return;
  }

  gs[0] = slice.to_dynamic(gs_init[0][:max_cnt_p1]);
  gs[1] = slice.to_dynamic(gs_init[1][:max_cnt_p2]);
  return;
}


regular_combat :: proc(game_state: ^GameState) -> (winner: int) {

  history: [dynamic]GameState;
  for len(game_state[0]) != 0 && len(game_state[1]) != 0 {

    for games in history {
      if slice.equal(games[0][:], game_state[0][:]) &&
      slice.equal(games[1][:], game_state[1][:]) {
        return 0;
      }
    }

    game_state_current := copy_game_state(game_state^, 0, 0);
    append(&history, game_state_current);

    card_player1 := pop_front(&game_state[0]);
    card_player2 := pop_front(&game_state[1]);

    if card_player1 > card_player2 {
      append(&game_state[0], card_player1, card_player2);
    } else {
      append(&game_state[1], card_player2, card_player1);
    }
  }

  return len(game_state[0]) == 0 ? 1 : 0;
}

main :: proc() {
  // Load
  batch := string(#load("input.txt"));
  /* batch := string(#load("input-test.txt")); */

  part1, part2 := run_program(batch);
  fmt.println("Result part 1:", part1);
  fmt.println("Result part 2:", part2);
}
