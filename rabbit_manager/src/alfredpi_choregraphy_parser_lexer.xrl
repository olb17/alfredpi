% The Definitions section defines regexps for each token.

Definitions.

STRING	   = "[^"]*"
INT        = [+-]?[0-9][0-9_]*
COLOR      = ~[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]
ACTION     = [a-z][a-zA-Z0-9_]*
VAR        = var
EXEC       = exec
AND        = and
END        = end
REPEAT     = repeat
VARIABLE   = [A-Z][a-zA-Z0-9_]*
NEWLINE    = \n+
WHITESPACE = [\s\t\n\r]
COMMENT    = #.*

% The Rule section defines what to return for each token. Typically you'd
% want the TokenLine and the TokenChars to capture the matched
% expression.

Rules.

\=            : {token, {'=', TokenLine}}.
\,            : {token, {',', TokenLine}}.
{STRING}      : {token, {string, TokenLine, to_string(TokenChars)}}.
{VAR}         : {token, {var, TokenLine}}.
{EXEC}        : {token, {exec, TokenLine}}.
{AND}         : {token, {and_token, TokenLine}}.
{END}         : {token, {end_token, TokenLine}}.
{REPEAT}      : {token, {repeat, TokenLine}}.
{COLOR}       : {token, {color, TokenLine, to_color(TokenChars)}}.
{INT}         : {token, {int, TokenLine, TokenChars}}.
{ACTION}      : {token, {action, TokenLine, TokenChars}}.
{VARIABLE}    : {token, {variable, TokenLine, TokenChars}}.
{KEYWORD}     : {token, {keyword, TokenLine, TokenChars}}.
{NEWLINE}     : {token, {newline, TokenLine}}.
{WHITESPACE}+ : skip_token.
{COMMENT}     : skip_token.


% The Erlang code section (which is mandatory), is where you can add
% erlang functions you can call in the Definitions. In this case we
% have a to_token to create a token for each named variable (this is
% not good style, but just to show how to use the code section).

Erlang code.

% Given a ":name", chop off : and return name as an atom.
to_color([$~|Chars]) ->
    [$# | Chars].

to_string(Chars) ->
    case Chars of
        [_First | Rest] ->
            case lists:reverse(Rest) of
                [_Last | ReversedRest] ->
                    lists:reverse(ReversedRest);
                [] -> []
            end;
        [] -> []
    end.
    
