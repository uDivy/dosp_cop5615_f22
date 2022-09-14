-module(bitcoin).
-export([main/0]).

main() -> 
    {ok, Value} = io:read("Please add the number of Zeroes! "),
    io:fwrite("The number of Zeroes you entered is ~w~n",[Value]),
    AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",
    Length = 10,
    Ranstring = lists:foldl(fun(_, Acc) ->
                        [lists:nth(rand:uniform(length(AllowedChars)),
                                   AllowedChars)]
                                ++ Acc
                end, [] , lists:seq(1, Length)),
    io:fwrite("The random string is ~p~n", [string:concat("divyaupadhyay",Ranstring)]),
    io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,
    string:concat("divyaupadhyay",Ranstring)))]).


