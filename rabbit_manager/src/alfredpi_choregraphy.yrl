Nonterminals
  root
  instruction
  instructions
  exec_instructions
  arguments
  expr
.

Terminals
  string
  int
  color
  action
  keyword
  newline
  variable
  ','
  '='
  var
  exec
  and_token
  end_token
  repeat
.

Rootsymbol
   root
.

Right 100 '='.

root -> instructions : '$1'.

instructions -> instruction : ['$1'].
instructions -> instruction instructions : lists:append(['$1'], '$2').

instruction -> action : build_action( '$1', []).
instruction -> action arguments : build_action( '$1', '$2').
instruction -> var variable '=' expr : {assign, '$2', '$4'}.
instruction -> newline : {noop}.
instruction -> exec instructions exec_instructions end_token : {exec, lists:append(['$2'], '$3')}.
instruction -> repeat expr instructions end_token : {repeat, '$2', '$3'}.

exec_instructions -> and_token instructions : ['$2'].
exec_instructions -> and_token instructions exec_instructions : lists:append(['$2'], '$3').

arguments -> expr : ['$1'].
arguments -> expr ',' arguments : lists:append(['$1'], '$3').

expr -> int : unwrap_int('$1').
expr -> color : unwrap_color('$1').
expr -> variable : '$1'.
expr -> string : unwrap_string('$1').

Erlang code.

unwrap_int({int, Line, Value}) -> {int, Line, list_to_integer(lists:delete($_, Value))}.
unwrap_color({color, Line, Value}) -> {color, Line, Value}.
unwrap_string({string, Line, Value}) -> {string, Line, list_to_binary(Value)}.
build_action({action, Line, Action}, Arguments) -> {action, Line, Action, Arguments}.
