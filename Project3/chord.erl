-module(chord).
-behaviour(gen_server).
-compile(export_all).

init([NumNodes, NumRequests]) ->
    {ok, {[],NumNodes, NumRequests}}.

master(Args) -> 
    {NumNodes, NumRequests} = Args,
    % io:format("~w ~w",[NumNodes,NumRequests]),
    M = list_to_integer(erlang:float_to_list(math:ceil(math:log2(NumNodes)),[{decimals,0}])),
    N = list_to_integer(erlang:float_to_list(math:ceil(math:pow(2,M)),[{decimals,0}])),
    Keys = generate_keys(N, NumNodes, []),

    gen_server:start_link({global,chord}, ?MODULE, [NumNodes,NumRequests],[]),
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
        generate_keys(N, Bound-1, Keys ++ [Rnd_key])
    end.

for_master(I, NumNodes, _, _) when I == NumNodes + 1 ->  
    ok;
for_master(I, NumNodes, Keys, NumRequests) when I =< NumNodes ->
    % Var2 = lists:nth(I, Keys),
    gen_server:cast(peertopeer,{initiate, {NumRequests,Keys}}),
    for_master(I+1, NumNodes, Keys, NumRequests).

handle__cast({hibernate, Avg},{Hoplist, NumNodes, NumRequests}) ->
    New_List = Hoplist ++ [Avg],
    if Avg == NumNodes ->
        AvgHops = peertopeer:calculating_avg_hopcount(NumNodes, NumRequests, Hoplist),
        io:format("Converged with average hops ~w~n",[AvgHops]);
    true ->
        ok
    end,
    {noreply,{Hoplist ++ [Avg],NumNodes,NumRequests}}.