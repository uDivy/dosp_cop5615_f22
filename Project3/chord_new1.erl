-module(chord_new1).
-behaviour(gen_server).
-compile(export_all).

-record(state, {numRequests, keys, id, finTable, target, hopcount, hoplist, source}).

init([NumNodes, NumRequests]) ->
    io:format("Inside Init"),
    {ok, {[],NumNodes, NumRequests}}.

master(Args) ->
    {NumNodes, NumRequests} = Args,
    gen_server:start_link({global, master}, ?MODULE, [NumNodes,NumRequests],[]),
    M = list_to_integer(erlang:float_to_list(math:ceil(math:log2(NumNodes)),[{decimals,0}])),

    N = list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])),

    Keys = generate_keys(N, NumNodes, []),

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
    % Id = peertopeer:getter(Var2),
    my_handle_cast(getter(Var2),{initiate, {NumRequests,Keys}},[]),
    % peertopeer:my_handle_cast({initiate, NumRequests, Keys},[1,1,1,1,1,1,1,1]),
    for_master(I+1, NumNodes, Keys, NumRequests).


getter(I) ->
    % io:format("In Getter Function"),
    Id = integer_to_list(I),
    ID2 = string:concat("0000", Id),
    ID3 = list_to_integer(ID2),
    % io:format("~p",[ID2]).
    ID3.


make(NumNodes, Keys, M, NumRequests) ->
    io:format("Inside Make",[]),
    for_make(1, NumNodes, Keys, M, NumRequests).

for_make(I, NumNodes, _, _, _) when I == NumNodes + 1 ->  
    ok;
for_make(I, NumNodes, Keys,M, NumRequests) when I =< NumNodes ->
    Name = getter(lists:nth(I, Keys)), 
    io:format("~w",[Name]),
    % gen_server:start_link(?MODULE, [lists:nth(I, Keys), M, Keys, NumRequests],[]),
    for_make(I+1, NumNodes, Keys,M, NumRequests).


my_handle_cast(Id, {initiate,{NumRequests,Keys}}, []) ->
    io:format("ID=~w Received initiate. Will start lookup", [Id]).
    % find_nearby(Id, 1, NumRequests, Keys, FinTable, 0),
    % {noreply, [NumRequests, Keys, Id, FinTable, 0,0,[],1]}.