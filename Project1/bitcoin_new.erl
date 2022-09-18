-module(bitcoin_new).
-compile(export_all).

main(Value, Leading_Zeroes) ->
    % {ok, Value} = io:read("Please insert the number of Zeroes! "),
    % Leading_Zeroes = lists:concat(lists:duplicate(Value, "0")),
    Pid1 = spawn(bitcoin_new, gen_randm_string, []),
    Pid1 ! {self(), {10, genstring}},
    receive Finalstring -> Finalstring end,
    FinalRanString = element(2, Finalstring),
    % io:fwrite("The Final string is ~p~n", [FinalRanString]),
    Pid2 = spawn(bitcoin_new,gen_sha256_hash,[]),
    Pid2 ! {self(), {FinalRanString, genhash}},
    receive SHA256 -> SHA256 end, 
    FinalSHA256 = element(2, SHA256),
    % io:fwrite("The sha256 hash is ~p~n", [FinalSHA256]).
    Check_Zeroes = string:slice(FinalSHA256, 0, Value),
    Status = string:equal(Check_Zeroes,Leading_Zeroes),
    if 
        Status -> 
          io:fwrite("The required coin is ~p  ~p~n", [FinalRanString,FinalSHA256]); 
        true -> 
            main(Value, Leading_Zeroes) 
      end.
  

gen_randm_string() ->
    receive
        {Client, {Length, genstring}} ->
            AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",
            Ranstring = lists:foldl(fun(_, Acc) ->
                                    [lists:nth(rand:uniform(length(AllowedChars)),
                                      AllowedChars)]
                              ++ Acc
                        end, [] , lists:seq(1, Length)),
            Finalstring = string:concat("devangkale", Ranstring),
            Client ! {self(), Finalstring}
    end,
    gen_randm_string().

gen_sha256_hash() ->
    receive
        {Client, {FinalRanString, genhash}} ->
            SHA256 = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, FinalRanString))]),
            Client ! {self(), SHA256}
    end,
    gen_sha256_hash().


run() ->
    {ok, Value} = io:read("Please insert the number of Zeroes! "),
    Leading_Zeroes = lists:concat(lists:duplicate(Value, "0")),
    spawn(bitcoin_new, main, [Value, Leading_Zeroes]).