-module(gossip2).
-compile(export_all).
-import(string,[concat/2]). 

build_topology(Types) ->
    case Types of
        {line, NumNodes} when NumNodes > 0 ->
            LineTopology = build_line(NumNodes, [],1),
            % io:format("The Line Topology is: ~p~n",[LineTopology]),
            Neighbour = find_my_neighbour_1d(NumNodes, NumNodes, LineTopology, []),
            % io:format("~w~n", [Neighbour]),
            % register(mycounter, spawn(gossip, await_result, [0, 0])),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_line(NumNodes, NumNodes, LineTopology, Neighbour, mycounter),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
        {_, NumNodes} when NumNodes == 0 ->
            unknown
    end.

random_selection_of_living_actors(Curprocess, Count, Sender_id, [First | Rest], Num) ->
    if Count == Num ->
        [Count,0];
    true -> 
        if First == Curprocess ->
            random_selection_of_living_actors(Curprocess, Count+1, Sender_id, Rest, Num);
        true ->
            Status = is_process_alive(First),
            if Status == false ->
                random_selection_of_living_actors(Curprocess, Count+1, Sender_id, Rest, Num);
            true ->
                [Count, First]
            end
        end
    end.
    




listen(Count) ->
    receive
        {Msg, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;
        {Gossip, Sender_id, Neighbour, Pos, LineTopology, connectline} ->
            if Count > 10 ->
                % Sender_id ! done,
                io:format("MY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline},
                exit(self());
            true ->
                io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                Blockof = lists:nth(Pos, Neighbour),
                Coln = rand:uniform(length(Blockof)),
                if Coln == 1 ->
                    if Pos == 1 ->
                        Posnew = Pos + 1;
                    true ->
                        Posnew = Pos - 1
                    end;
                true ->
                    Posnew = Pos + 1
                end,
                Heardby = lists:nth(Coln, Blockof),
                io:format("Lets see ~w ~w ~n",[is_process_alive(Heardby), Heardby]),
                case is_process_alive(Heardby) of 
                    false -> 
                        lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline};
                    _ -> Heardby ! {"youknowwhat", Sender_id, Neighbour, Posnew, LineTopology, connectline}
                end
            end
    end,
    listen(Count+1).

%% BUILD TOPOLOGY
build_line(0, LineTopology, _)  ->
    LineTopology;
build_line(NumNodes, Rest, Row) ->
    % AllowedChars = "qwertyuiopasdfghjklzxcvbnm",

    % Ranstring = lists:foldl(fun(_, Acc) ->
    %                 [lists:nth(rand:uniform(length(AllowedChars)),
    %                             AllowedChars)]
    %                           ++ Acc
    %                 end, [] , lists:seq(1, 10)),

    % Str = Ranstring ++ "human" ++ integer_to_list(Row) ++ integer_to_list(NumNodes),
    % register(list_to_atom(Str), spawn(gossip2, listen, [0])),
    Pid = spawn(gossip2, listen, [0]),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        io:format("",[])
    end,
    build_line(NumNodes-1, [Pid | Rest], Row+1).


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
        {donedone} ->
            exit(normal)
            % io:format("done ~n",[]),
            % mycounter ! {counter, self()}
        % {value, Count} ->
        %     io:format("Count ~n",[]),
        %     if Count == NumNodes*10 ->
        %         done;
        %     true ->
        %         you_know_what_line(NumNodes, Pos, LineTopology, Neighbour, mycounter)
        %     end
    end;
you_know_what_line(NumNodes, Pos, LineTopology,Neighbour, mycounter) when Pos == NumNodes->
    Heardby = lists:nth(Pos, LineTopology),
    % io:format("~w ~n",[Heardby]),
    Heardby ! {"youknowwhat", self(), Neighbour, Pos,  LineTopology, connectline},
    % receive
    %     ack ->
    %         io:format("Final ~w ~n",[Heardby])
    % end.
    you_know_what_line(NumNodes, 0, LineTopology,Neighbour, mycounter).