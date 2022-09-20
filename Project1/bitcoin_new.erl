-module(bitcoin_new).
-compile(export_all).
-define (TIMEOUT, 500).

gen_randm_string() ->
    receive
        {Client, {Length, genstring}} ->
            AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",

            Ranstring = lists:foldl(fun(_, Acc) ->
                                    [lists:nth(rand:uniform(length(AllowedChars)),
                                      AllowedChars)]
                              ++ Acc
                        end, [] , lists:seq(1, Length)),

            UFID = "devangkale",
            Finalstring = string:concat(UFID, Ranstring),
            Client ! {self(), Finalstring}
            % gen_randm_string()

    % after ?TIMEOUT ->
    %     exit(no_activity)
    end,
    gen_randm_string().

gen_sha256_hash() ->
    receive
        {Client, {FinalRanString, genhash}} ->
            SHA256 = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, FinalRanString))]),
            Client ! {self(), SHA256}
        % gen_sha256_hash()

    % after ?TIMEOUT ->
    %     exit(no_activity)
    end,
    gen_sha256_hash().


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
          io:fwrite("The required coin is ~p  ~p~n", [FinalRanString,FinalSHA256]),
          {_, Time1} = statistics(runtime),
          {_, Time2} = statistics(wall_clock),
          U1 = Time1,
          U2 = Time2,
          U3 = Time1/Time2,
          io:format("CPU Time : ~p, Real Time: ~p, Ratio = ~p~n",[U1, U2, U3]),
          main(Value, Leading_Zeroes);
        true -> 
            main(Value, Leading_Zeroes)
      end.

run() ->

    {ok, Value} = io:read("Please insert the number of Zeroes: "),
    Leading_Zeroes = lists:concat(lists:duplicate(Value, "0")),
    spawn(bitcoin_new, main, [Value, Leading_Zeroes]).
