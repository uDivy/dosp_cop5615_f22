-module(peertopeer).
-compile(export_all).
-behaviour(gen_server).

init([Id, M, Keys, NumRequests]) ->
    FingerTable = create_fin_table(Id, M, 1, Keys, []),
    {ok, [NumRequests, [], Id, FingerTable, 0, 0, [], 0]}.


make(NumNodes, Keys, M, NumRequests) ->
    % io:format("Print statement~n",[]).
    for_make(1, NumNodes, Keys, M, NumRequests).

for_make(I, NumNodes, _, _, _) when I == NumNodes + 1 ->  
    ok;
for_make(I, NumNodes, Keys,M, NumRequests) when I =< NumNodes -> 
    gen_server:start_link(?MODULE,[lists:nth(I, Keys), M, Keys, NumRequests],[]),
    getter(lists:nth(I, Keys)),
    for_make(I+1, NumNodes, Keys,M, NumRequests).

getter(I) ->
    Id = integer_to_list(I),
    string:concat("ChordP2P",Id).

create_fin_table(Id,M,I,Keys,FinTable) when I > M ->
    FinTable;
create_fin_table(Id,M,I,Keys,FinTable) when I == 0->
    Var = float_to_list(math:pow(2,M), [{decimals,0}]),
    LowValue = Id + 1 rem Var,
    HighValue = Id + 2 rem Var,

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
        Suppose = lists:nth(1,Fin) >= math:pow(2,M),
        FinTableNew = FinTable ++ if Suppose ->
                                [list_to_integer(erlang:float_to_list(lists:nth(1,Fin),[{decimals,0}])) rem list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}]))];
                                true ->
                                    [lists:nth(1,Fin)]
                                end,
        create_fin_table(Id,M,I+1,Keys,FinTableNew);
create_fin_table(Id,M,I,Keys,FinTable) when I =< M->
    Var = float_to_list(math:pow(2,M), [{decimals,0}]),
    Varl = float_to_list(math:pow(2,I-1), [{decimals,0}]),
    Varh = float_to_list(math:pow(2,I), [{decimals,0}]),
    LowValue = Id + Varl rem Var,
    HighValue = Id + Varh rem Var,

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
        Suppose = lists:nth(1,Fin) >= math:pow(2,M),
        FinTableNew = FinTable ++ if Suppose  ->
                                [list_to_integer(erlang:float_to_list(lists:nth(1,Fin),[{decimals,0}])) rem list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}]))];
                                true ->
                                    [lists:nth(1,Fin)]
                                end,
        create_fin_table(Id,M,I+1,Keys,FinTableNew).

find_nearby(Id, I, Bound, Keys, FinTable, Hopcount) when i == Bound ->
    io:format("ID=~w, All set initiating requests",[Id]);
find_nearby(Id, I, Bound, Keys, FinTable, Hopcount) when i < Bound ->
    Key = my_rand_key(Keys, Id),
    Target = lists:nth(index_dest(Key, FinTable, 1),lists:sort(FinTable)),

    gen_server:cast(peertopeer:getter(Target),{lookup, {Key, Id, Hopcount+1}}),
    timer:sleep(1000),
    find_nearby(Id, I + 1, Bound, Keys, FinTable, Hopcount).

my_rand_key(Keys, Id) ->
    My_key = lists:nth(rand:uniform(length(Keys)),Keys),
    if My_key == Id ->
        my_rand_key(Keys, Id);
    true ->
        My_key
    end.

index_dest(Target, FinTable, I) when i < length(FinTable) ->
    Look = lists:nth(I, lists:sort(FinTable)),
    if Look > Target ->
        I - 1;
    true ->
        index_dest(Target, FinTable, I+1)
    end;
index_dest(_, FinTable, I) when I == length(FinTable) ->
    I -1.

handle_cast({initiate, {NumRequests, Keys}},[_, _, Id, FinTable, _, _, _, _]) ->
    find_nearby(Id, 1, NumRequests, Keys, FinTable, 0),
    {noreply, [NumRequests, Keys, Id, FinTable, 0,0,[],1]};

handle_cast({lookup, {Targetkey, Source, Hopcount}},[NumRequests, Keys, Id, FinTable, Targetkey, Hopcount, _, _]) ->
    io:format("ID = ~w Received Lookup Request for Target=~w",[Id,Targetkey]),
    if Targetkey == Id ->
        gen_server:cast();
        {noreply, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount+1,[],1]};
    true ->
        Target = lists:nth(index_dest(Targetkey, FinTable, 1),lists:sort(FinTable)),
        gen_server:cast(),
        {noreply, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount+1,[],1]}
    end.

handle_cast({notify, {Hopcount}},[NumRequests, Keys, Id, FinTable, Target, Hopcount, Hoplist]) ->
    Hoplist = Hoplist ++ [Hopcount],
    io:format("ID = ~w Received notify",[Id]),
    if length(Hoplist) == NumRequests ->
        gen_server:cast();
    true ->
        ok
    end,
    {noreply, [NumRequests, Keys, Id, FinTable, Target, Hopcount,Hoplist]}.