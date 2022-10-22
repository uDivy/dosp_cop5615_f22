-module(chord).
-compile(export_all).
-behaviour(gen_server).

init([NumNodes, NumRequests]) ->
    {ok, {[],NumNodes, NumRequests}}.

master(Args) -> 
    {NumNodes, NumRequests} = Args,
    M = list_to_integer(erlang:float_to_list(math:ceil(math:log2(NumNodes)),[{decimals,0}])),
    N = list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])),
    Keys = generate_keys(N, NumNodes, []),
    io:format("~w ~w ~w ~w ~n",[NumNodes, NumRequests, M, length(Keys)]),
    gen_server:start_link(?MODULE,[NumNodes,NumRequests],[]),
    io:format("~w ~n",[length(Keys)]),
    peertopeer:make(NumNodes, Keys, M, NumRequests),
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
        generate_keys(N, Bound-1, [Rnd_key | Keys])
    end.

for_master(I, NumNodes, _, _) when I == NumNodes +1 ->  
    ok;
for_master(I, NumNodes, Keys, NumRequests) when I =< NumNodes -> 
    gen_server:cast(peertopeer:getter(lists:nth(I, Keys))),
    for_master(I+1, NumNodes, Keys, NumRequests).

handle_cast({hibernate, Avg},{Hoplist, NumNodes, NumRequests}) ->
    New_List = Hoplist ++ [Avg],

    if length(New_List) == NumNodes ->
        AvgHops = lists:sum(New_List)/NumNodes,
        io:format("Converged with average hops ~w~n",[AvgHops]),
        exit(self);
    true ->
        ok
    end.