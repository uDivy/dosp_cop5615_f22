-module(peertopeer).
-behaviour(gen_server).
-compile(export_all).
-record(state, {numRequests, keys, id, finTable, target, hopcount, hoplist, source}).

init([Id, M, Keys, NumRequests]) ->
    FingerTable = create_fin_table(Id, M, 1, Keys, []),
    {ok, [NumRequests, [], Id, FingerTable, 0, 0, [], 0]}.

make(NumNodes, Keys, M, NumRequests) ->
    for_make(1, NumNodes, Keys, M, NumRequests).

for_make(I, NumNodes, Keys, _, NumRequests) when I == NumNodes + 1 ->  
    call_fingertable(NumNodes, NumRequests, Keys);
for_make(I, NumNodes, Keys,M, NumRequests) when I =< NumNodes ->
    Name = getter(lists:nth(I, Keys)), 
    % io:format("~w",[Name]),
    gen_server:start_link({global, peertopeer}, ?MODULE, [lists:nth(I, Keys), M, Keys, NumRequests],[]),
    for_make(I+1, NumNodes, Keys,M, NumRequests).

getter(I) ->
    % io:format("In Getter Function"),
    Id = integer_to_list(I),
    string:concat("ChordP2P",Id),
    list_to_integer(Id).

create_fin_table(Id,M,I,Keys,FinTable) when I > M ->
    FinTable;

create_fin_table(Id,M,I,Keys,FinTable) when I == 1 ->
    Var = list_to_integer(float_to_list(math:pow(2,M), [{decimals,0}])),
    LowValue = (Id + 1) rem Var,
    HighValue = (Id + 2) rem Var,

    Fin = 
        if LowValue < HighValue ->
            Let = lists:filter(fun(X) -> X >= LowValue end, Keys),
            Let1 = 
                if length(Let) > 0 ->
                    Let;
                true ->
                    lists:sort(lists:filter(fun(X) -> X < LowValue end, Keys))
                end;

        true ->
            Let1 = lists:map(fun(X) -> X + list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])) end,
                                            lists:filter(fun(X) -> X < LowValue end, Keys)),
            
            Let1 ++ lists:sort(lists:filter(fun(X) -> X >= LowValue end, Keys))
        end,
        Suppose = (lists:nth(1,Fin)) >= (math:pow(2,M)),

        FinTableNew = FinTable ++ if Suppose ->
                                [round(lists:nth(1,Fin)) rem 
                                    round(math:ceil(math:pow(2,M)))];
                                true ->
                                    [lists:nth(1,Fin)]
                                end,

        create_fin_table(Id,M,I+1,Keys,FinTableNew);


create_fin_table(Id,M,I,Keys,FinTable) when I =< M ->
    Var = list_to_integer(float_to_list(math:pow(2,M), [{decimals,0}])),
    Varl = list_to_integer(float_to_list(math:pow(2,I-1), [{decimals,0}])),
    Varh = list_to_integer(float_to_list(math:pow(2,I), [{decimals,0}])),
    LowValue = (Id + Varl) rem Var,
    HighValue = (Id + Varh) rem Var,

    Fin = 
        if LowValue < HighValue ->
            Let = lists:filter(fun(X) -> X >= LowValue end, Keys),
            Let1 = 
                if length(Let) > 0 ->
                    Let;
                true ->
                    lists:sort(lists:filter(fun(X) -> X < LowValue end, Keys))
                end;

        true ->
            Let1 = lists:map(fun(X) -> X + list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])) end,
                                            lists:filter(fun(X) -> X < LowValue end, Keys)),
            
            Let1 ++ lists:sort(lists:filter(fun(X) -> X >= LowValue end, Keys))
        end,

        Suppose = ((lists:nth(1,Fin)) >= (math:pow(2,M))),
        if Suppose ->
            Addl = (round(lists:nth(1,Fin))) rem (round(math:ceil(math:pow(2,M))));
        true ->
            Addl = lists:nth(1,Fin)
        end,

        FinTableNew = [Addl | FinTable],

        create_fin_table(Id,M,I+1,Keys,FinTableNew).

find_nearby(Id, I, Bound, Keys, Nn, Nr) when I == Bound ->
    % io:format("ID=~w, All set initiating requests",[Id]);
    gen_server_cast(Nn, Nr);
find_nearby(Id, I, Bound, Keys, FinTable, Hopcount) when I < Bound ->
    Key = my_rand_key(Keys, Id),
    Target = lists:nth(index_dest(Key, FinTable, 1),lists:sort(FinTable)),

    gen_server:cast(peertopeer:getter(Target),{lookup, Key, Id, Hopcount+1}),
    timer:sleep(1000),
    find_nearby(Id, I + 1, Bound, Keys, FinTable, Hopcount).

call_fingertable(NumNodes, NumRequests, Keys) ->
    io:format("Caluculating the FingerTable~n"),
    Fintable = create_fin_table(1,1,2,[],Keys),
    timer:sleep(NumNodes*10),
    io:format("Sending Requests~n"),
    chord:handle__cast({hibernate, NumNodes},{Keys, NumNodes, NumRequests}).

calculating_avg_hopcount(NumNodes, NumRequests, Hoplist) ->
    K = my_rand_key(Hoplist, 1),
    Successornode = index_dest(K, Hoplist, 1),
    find_nearby(K, 1, 1, Hoplist, NumNodes, NumRequests).

my_rand_key(Keys, Id) ->
    My_key = lists:nth(rand:uniform(length(Keys)),Keys),
    if My_key == Id ->
        my_rand_key(Keys, Id);
    true ->
        My_key
    end.

index_dest(Target, FinTable, I) when I < length(FinTable) ->
    timer:sleep(2),
    Look = lists:nth(I, lists:sort(FinTable)),
    if Look > Target ->
        I - 1;
    true ->
        index_dest(Target, FinTable, I+1)
    end;
index_dest(_, FinTable, I) when I == length(FinTable) ->
    I - 1.

my_handle_cast({initiates, {NumRequests,Keys}}, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount, Hoplist, Source]) ->
    % io:format("ID=~w Received initiate. Will start lookup", [Id]).
    find_nearby(Id, 1, NumRequests, Keys, FinTable, 0),
    {noreply, [NumRequests, Keys, Id, FinTable, 0,0,[],1]}.
gen_server_cast(Nn, Nr) ->
    if Nn > 2000 ->
        timer:kill_after(3000);
    true ->
        Nextindex = math:log(Nn) + (10/Nr) - random:uniform(1)
    end.
handle_cast({global,lookup, {Targetkey, Source, Hopcount}},[NumRequests, Keys, Id, FinTable, Targetkey, Hopcount, Hoplist, Source]) ->
    io:format("ID = ~w Received lookup Request for Target=~w",[Id,Targetkey]),
    if Targetkey == Id ->
        gen_server:cast(getter(Source),{notify, {Hopcount + 1}}),
        {noreply, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount+1,Hoplist,Source]};

    true ->
        Target = lists:nth(index_dest(Targetkey, FinTable, 1),lists:sort(FinTable)),
        gen_server:cast({global,client},{lookup, {Targetkey, Source, Hopcount+1}}),
        {noreply, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount+1,Hoplist, Source]}
    end;
handle_cast({notify, {Hopcount}},[NumRequests, Keys, Id, FinTable, Target, Hopcount, Hoplist, Source]) ->
    Hoplist = Hoplist ++ [Hopcount],
    io:format("ID = ~w Received notify. Lookup Successful",[Id]),
    if length(Hoplist) == NumRequests ->
        VarSum = (lists:sum(Hoplist))/NumRequests,
        gen_server:cast({global, master},{hibernate,VarSum});
    true ->
        ok
    end,
    {noreply, [NumRequests, Keys, Id, FinTable, Target, Hopcount,Hoplist, Source]}.