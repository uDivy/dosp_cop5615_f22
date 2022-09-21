-module(bitcoin_alt).
-compile(export_all).
-define (TIMEOUT, 5).

gen_coin(Value, Leading_Zeroes) ->
    AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",

    Ranstring = lists:foldl(fun(_, Acc) ->
                    [lists:nth(rand:uniform(length(AllowedChars)),
                                AllowedChars)]
                              ++ Acc
                    end, [] , lists:seq(1, 10)),

    UFID = "devangkale",
    Finalstring = string:concat(UFID, Ranstring),
    FinalSHA256 = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256, Finalstring))]),
    Check_Zeroes = string:slice(FinalSHA256, 0, Value),
    Status = string:equal(Check_Zeroes,Leading_Zeroes),
    if 
        Status -> 
            io:fwrite("The required coin is ~p  ~p~n", [Finalstring,FinalSHA256]),
            {_, Time1} = statistics(runtime),
            {_, Time2} = statistics(wall_clock),
            U1 = Time1,
            U2 = Time2,
            U3 = Time1/Time2,
            io:format("PID: ~p CPU Time : ~p, Real Time: ~p, Ratio = ~p~n",[self(),U1, U2, U3]);
        true ->
                % io:fwrite("Coin Not Found ~n")
            []
    end.

main(0, _, _) ->
    io:fwrite("Closing the worker with PID::~w~n",[self()]),
    exit(self());
    
main(N, KValue, Leading_Zeroes) ->
    % io:fwrite("Generating coin on ~w~n", [self()]),
    gen_coin(KValue, Leading_Zeroes),
    main(N-1, KValue, Leading_Zeroes).

for_run(0,_,_,_) ->  
        io:fwrite("All workers are spawned now:: Bye!!~n");

for_run(N,KValue,Leading_Zeroes, Workload) when N > 0 -> 
    Pid = spawn(bitcoin_alt, main, [Workload, KValue, Leading_Zeroes]), 
    io:fwrite("Worker generated with the PID  ~w~n", [Pid]),
    for_run(N-1,KValue,Leading_Zeroes, Workload).

run() ->
   {ok, KValue} = io:read("Please insert the number of Zeroes: "),
   Leading_Zeroes = lists:concat(lists:duplicate(KValue, "0")),
   for_run(8,KValue,Leading_Zeroes, 100000).