-module(fiar_core).
-author('euen@inakanetworks.com').

-type chip() :: 1|2.
-type column() :: [chip()].
-type board() ::
  {column(), column(), column(), column(), column(), column(), column()}.
-type col() :: 1..7.

-record(match, {board::board(), next_chip = 2 :: chip()}).
-opaque match() :: #match{}.

-export_type([chip/0, board/0, col/0, match/0]).
-export([start/0, play/2, get_next_chip/1, to_json/1]).

-spec start() -> match().
start()  -> 
  #match{board = {[], [], [], [], [], [], []}}.

-spec play(col(), match()) -> won | drawn | {next, match()}.
play(Col, _) when Col < 1 orelse Col > 7 ->
  throw(invalid_column);
play(Col, Match = #match{board = Board, next_chip = NextChip}) ->
  Column = element(Col, Board),
  NewColumn = [NextChip|Column],
  NewBoard = setelement(Col, Board, NewColumn),
  NewMatch = Match#match{board = NewBoard,
             next_chip = diff_chip(NextChip)},
  case Column of
    [_, _, _, _, _, _, _] -> throw(invalid_column);
    [NextChip, NextChip, NextChip | _] ->
      {won, NewMatch};
    _ ->
      Status = analyze(Col, NewColumn, NextChip, NewBoard),
      {Status, NewMatch}
  end.

-spec get_next_chip(match()) -> chip().
get_next_chip(Match) ->
  Match#match.next_chip.

diff_chip(1) -> 2;
diff_chip(2) -> 1.

analyze(Col, Column, Chip, Board) ->
  RowNum = length(Column),
  case wins_row(RowNum, Chip, Board) orelse
       wins_left_diag(Col, RowNum, Chip, Board) orelse
       wins_right_diag(Col, RowNum, Chip, Board) of
          true -> won;
          false ->
            case is_full(Board) of
                true -> drawn;
                false -> next
            end
  end.

wins_row(RowNum, Chip, Board) ->
  Row = get_row(RowNum, Board),
  contains_four(Chip, Row).
 
contains_four(_Chip, List) when length(List) < 4 -> false;
contains_four(Chip, [Chip, Chip, Chip, Chip | _ ])  -> true;
contains_four(Chip, [ _ | Rest ]) -> contains_four(Chip, Rest).

get_row(RowNum, Board) ->
  Columns = tuple_to_list(Board),
  lists:map(fun(Column) -> get_chip(RowNum, Column) end, Columns).

get_left_diag(Col, RowNum, Board) ->
  UpLeftDiag = get_up_left_diag(Col, RowNum, Board, []),
  DownLeftDiag = get_down_left_diag(Col, RowNum, Board, []),
  UpLeftDiag ++ tl(lists:reverse(DownLeftDiag)).

get_up_left_diag(Col, RowNum, Board, Acc) when Col =:= 1; RowNum =:= 7 ->
  Chip = get_chip(Col, RowNum, Board),
  [Chip | Acc];
get_up_left_diag(Col, RowNum, Board, Acc) ->
  Chip = get_chip(Col, RowNum, Board),
  Next = [Chip | Acc],
  get_up_left_diag(Col-1, RowNum+1, Board, Next).

get_down_left_diag(7, RowNum, Board, Acc) ->
  Chip = get_chip(7, RowNum, Board),
  [Chip | Acc];
get_down_left_diag(Col, 1, Board, Acc) -> 
  Chip = get_chip(Col, 1, Board),
  [Chip | Acc];
get_down_left_diag(Col, RowNum, Board, Acc) ->
  Chip = get_chip(Col, RowNum, Board),
  Next = [Chip | Acc],
  get_down_left_diag(Col+1, RowNum-1, Board, Next).

get_right_diag(Col, RowNum, Board) ->
  DownRightDiag = get_down_right_diag(Col, RowNum, Board, []),
  UpRightDiag = get_up_right_diag(Col, RowNum, Board, []),
  DownRightDiag ++ tl(lists:reverse(UpRightDiag)).

get_down_right_diag(Col, RowNum, Board, Acc) when Col =:= 1; RowNum =:= 1 ->
  Chip = get_chip(Col, RowNum, Board),
  [Chip | Acc];
get_down_right_diag(Col, RowNum, Board, Acc) ->
  Chip = get_chip(Col, RowNum, Board),
  Next = [Chip | Acc],
  get_down_right_diag(Col-1, RowNum-1, Board, Next).

get_up_right_diag(Col, RowNum, Board, Acc) when Col =:= 7; RowNum =:= 7 ->
  Chip = get_chip(Col, RowNum, Board),
  [Chip | Acc];
get_up_right_diag(Col, RowNum, Board, Acc) ->
  Chip = get_chip(Col, RowNum, Board),
  Next = [Chip | Acc],
  get_up_right_diag(Col+1, RowNum+1, Board, Next).

get_chip(RowNum, Column) when length(Column) >= RowNum ->
  lists:nth(RowNum, lists:reverse(Column));
get_chip(_RowNum, _Column) -> 0.

get_chip(Col, RowNum, Board) ->
  Columns = tuple_to_list(Board),
  Column = lists:nth(Col, Columns),
  get_chip(RowNum, Column).

wins_left_diag(Col, RowNum, Chip, Board) ->
  Diag = get_left_diag(Col, RowNum, Board),
  contains_four(Chip, Diag).

wins_right_diag(Col, RowNum, Chip, Board) ->
  Diag = get_right_diag(Col, RowNum, Board),
  contains_four(Chip, Diag).

is_full(Board) ->
  Columns = tuple_to_list(Board),
  Fun = fun(Col) ->
         case length(Col) of
               7 -> true;
               _ -> false
          end
  end,
  lists:all(Fun, Columns).

to_json(#match{board = BoardTuple, next_chip = Chip}) ->
  Board = tuple_to_list(BoardTuple),
  {[{<<"board">>, Board}, {<<"next_chip">>, Chip}]}. 
