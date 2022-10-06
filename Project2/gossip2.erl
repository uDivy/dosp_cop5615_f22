-module(gossip2).
-compile(export_all).
-import(string,[concat/2]). 

build_topology(Types) ->
    case Types of
        {line, NumNodes} when NumNodes > 0 ->
            LineTopology = build_line(NumNodes, [],1),
            % io:format("The Line Topology is: ~p~n",[LineTopology]),
            Neighbour = find_my_neighbour_1d(NumNodes, NumNodes, LineTopology, []),
            % register(mycounter, spawn(gossip, await_result, [0, 0])),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_line(NumNodes, NumNodes, LineTopology, Neighbour, mycounter),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
        {_, NumNodes} when NumNodes == 0 ->
            unknown
    end.

listen(Count, Neighbour) ->
    receive
        {Gossip, Sender_id} ->
            % io:format("~w~n",[Neighbour]),
            Sender_id ! ack
            % if Count >= 10 ->
            %     Sender_id ! done,
            %     exit(self());
            % true ->
            %     io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count])
            %     % Rown = rand:uniform(length(Neighbour)),
            %     % Coln = rand:uniform(length(Rown)),
            %     % Blockof = lists:nth(Rown, Neighbour),
            %     % Heardby = lists:nth(Coln, Blockof),
            %     % case whereis(Heardby) of 
            %     %     undefined -> listen(Count)
            %     % end,
            %     % Heardby ! {"youknowwhat", Sender_id, Neighbour, connectline}
            % end
    end,
    listen(Count+1, Neighbour).

    
    
    
    
%% BUILD TOPOLOGY
build_line(0, LineTopology, _)  ->
    LineTopology;
build_line(NumNodes, Rest, Row) ->
    AllowedChars = "qwertyuiopasdfghjklzxcvbnm",

    Ranstring = lists:foldl(fun(_, Acc) ->
                    [lists:nth(rand:uniform(length(AllowedChars)),
                                AllowedChars)]
                              ++ Acc
                    end, [] , lists:seq(1, 10)),

    Str = Ranstring ++ "human" ++ integer_to_list(Row) ++ integer_to_list(NumNodes),
    build_line(NumNodes-1, [list_to_atom(Str) | Rest], Row+1).


await_result(Sender_id, Count) ->
    receive
        {counter, Sender_id} ->
            Sender_id ! {value, Count}
    end,
    await_result(Sender_id, Count+1).

%% Line Topology
find_my_neighbour_1d(0, 0, _, Neighbour) ->
    Neighbour;
find_my_neighbour_1d(NumNodes, Pos, LineTopology, Neighbour) ->
    case Pos of 
        1 -> find_my_neighbour_1d(0, 0, LineTopology, [[lists:nth(2, LineTopology)]|Neighbour]);
        NumNodes -> find_my_neighbour_1d(NumNodes, Pos-1, LineTopology, [[lists:nth(NumNodes-1, LineTopology)]|Neighbour]);
        _ -> find_my_neighbour_1d(NumNodes,Pos-1 , LineTopology, [[lists:nth(Pos-1, LineTopology),lists:nth(Pos+1, LineTopology)]| Neighbour])
    end.

you_know_what_line(NumNodes, Pos, LineTopology, Neighbour, mycounter) when Pos == 0 ->
    receive
        {done} ->
            mycounter ! {counter, self()};
        {value, Count} ->
            if Count == NumNodes ->
                done;
            true ->
                you_know_what_line(NumNodes, Pos, LineTopology, Neighbour, mycounter)
            end
    end;
you_know_what_line(NumNodes, Pos, LineTopology,Neighbour, mycounter) when Pos == NumNodes->
    Heardby = lists:nth(Pos, LineTopology),
    register(Heardby, spawn(gossip, listen, [1, Neighbour])),
    % io:format("~w ~n",[Heardby]),
    Heardby ! {"youknowwhat", self(), connect},
    receive
        ack ->
            io:format("Final ~w ~n",[Heardby])
    end.
    % you_know_what_line(NumNodes, 0, LineTopology,Neighbour, mycounter).