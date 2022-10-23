-module(chord).
-behaviour(gen_server).
-compile(export_all).


init([NumNodes, NumRequests]) ->
    {ok, {[],NumNodes,NumRequests}}.

master(Args) -> 
    {NumNodes, NumRequests} = Args,
    M = list_to_integer(erlang:float_to_list(math:ceil(math:log2(NumNodes)),[{decimals,0}])),

    N = list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])),

    Keys = generate_keys(N, NumNodes, []),

    % io:format("~w ~w ~w ~w ~n",[NumNodes, NumRequests, M, length(Keys)]),
    gen_server:start_link({global, master}, ?MODULE, [NumNodes,NumRequests],[]),
    % io:format("~w ~n",[length(Keys)]),
    make(NumNodes, Keys, M, NumRequests),
    for_master(1, NumNodes, Keys, NumRequests).

generate_keys(_, Bound, Keys) when Bound == 0->
    % [rand:uniform(N) || _ <- lists:seq(1, Bound)].
    lists:sort(Keys);

generate_keys(N, Bound, Keys) when Bound >= 1 ->
    Rnd_key = rand:uniform(N),
    Check = lists:member(Rnd_key, Keys),
    if  Check ->
        generate_keys(N, Bound, Keys);
    true ->
        generate_keys(N, Bound-1, Keys ++ [Rnd_key])
    end.

for_master(I, NumNodes, _, _) when I == NumNodes + 1 ->  
    ok;
for_master(I, NumNodes, Keys, NumRequests) when I =< NumNodes ->
    Var2 = lists:nth(I, Keys),
    Id2 = getter(Var2),
    gen_server:cast(Id2,{initiate,{NumRequests,Keys}}),
    for_master(I+1, NumNodes, Keys, NumRequests).


init([Id, M, Keys, NumRequests]) ->
    FingerTable = create_fin_table(Id, M, 1, Keys, []),
    {ok, [NumRequests, [], Id, FingerTable, 0, 0, [], 0]}.


make(NumNodes, Keys, M, NumRequests) ->
    % io:format("Print statement~n",[]).
    for_make(1, NumNodes, Keys, M, NumRequests).

for_make(I, NumNodes, _, _, _) when I == NumNodes + 1 ->  
    ok;
for_make(I, NumNodes, Keys,M, NumRequests) when I =< NumNodes ->
    Name = getter(lists:nth(I, Keys)), 
    gen_server:start_link({local, list_to_atom(Name)}, ?MODULE, [lists:nth(I, Keys), M, Keys, NumRequests],[]),
    for_make(I+1, NumNodes, Keys,M, NumRequests).

getter(I) ->
    % io:format("In Getter Function"),
    Id = integer_to_list(I),
    string:concat("ChordP2P",Id),
    Id.

create_fin_table(Id,M,I,Keys,FinTable) when I > M ->
    FinTable;

create_fin_table(Id,M,I,Keys,FinTable) when I == 0 ->
    Var = float_to_list(math:pow(2,M), [{decimals,0}]),
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
                                [list_to_integer(erlang:float_to_list(lists:nth(1,Fin),[{decimals,0}])) rem 
                                    list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}]))];
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
    I - 1.

handle_cast({initiate, {NumRequests, Keys}},[_, _, Id, FinTable, _, _, _, _]) ->
    io:format("ID=~w Received initiate. Will start lookup", [Id]),
    find_nearby(Id, 1, NumRequests, Keys, FinTable, 0),
    {noreply, [NumRequests, Keys, Id, FinTable, 0,0,[],1]};

handle_cast({lookup, {Targetkey, Source, Hopcount}},[NumRequests, Keys, Id, FinTable, Targetkey, Hopcount, Hoplist, Source]) ->
    io:format("ID = ~w Received lookup Request for Target=~w",[Id,Targetkey]),
    if Targetkey == Id ->
        gen_server:cast(peertopeer:getter(Source),{notify, {Hopcount + 1}}),
        {noreply, [NumRequests, Keys, Id, FinTable, Targetkey, Hopcount+1,Hoplist,Source]};

    true ->
        Target = lists:nth(index_dest(Targetkey, FinTable, 1),lists:sort(FinTable)),
        gen_server:cast(peertopeer:getter(Target),{lookup, {Targetkey, Source, Hopcount+1}}),
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
    {noreply, [NumRequests, Keys, Id, FinTable, Target, Hopcount,Hoplist, Source]};
    handle_cast({hibernate, Avg},{Hoplist, NumNodes, NumRequests}) ->
        New_List = Hoplist ++ [Avg],
    
        if length(New_List) == NumNodes ->
            AvgHops = (lists:sum(New_List))/NumNodes,
            io:format("Converged with average hops ~w~n",[AvgHops]),
            exit(self);
        true ->
            ok
        end,
        {noreply,{Hoplist ++ [Avg],NumNodes,NumRequests}}.