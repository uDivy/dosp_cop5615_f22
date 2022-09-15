-module(bitcoin).
-export([main/2, run/0]).


main(Value, Leading_Zeroes) -> 
    AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",
    Length = 10,
    Ranstring = lists:foldl(fun(_, Acc) ->
                        [lists:nth(rand:uniform(length(AllowedChars)),
                                   AllowedChars)]
                                ++ Acc
                end, [] , lists:seq(1, Length)),
    % io:fwrite("The random string is ~p~n", [string:concat("divyaupadhyay",Ranstring)]),
    SHA256 = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,
    string:concat("divyaupadhyay",Ranstring)))]),
    Check_Zeroes = string:slice(SHA256, 0, Value),
    % io:fwrite("The first ~w letter/s is/are ~p~n", [Value, Check_Zeroes]),
    Status = string:equal(Check_Zeroes,Leading_Zeroes),
    if 
      Status -> 
        io:fwrite("The required coin is ~p  ~p~n", [string:concat("divyaupadhyay",Ranstring),SHA256]); 
      true -> 
        main(Value, Leading_Zeroes) 
    end.

run() -> 
    {ok, Value} = io:read("Please insert the number of Zeroes! "),
    % io:fwrite("The number of Zeroes you entered is ~w~n",[Value]),
    Leading_Zeroes = lists:concat(lists:duplicate(Value, "0")),
    spawn(bitcoin, main, [Value, Leading_Zeroes]).