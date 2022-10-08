-module(pushsum).
-compile(export_all).
-import(string,[concat/2]). 

build_topology(Types) ->
    case Types of
        {line, NumNodes, pushsum} when NumNodes > 0 ->
            LineTopology = build_line_pushsum(NumNodes, [],1),
            % io:format("The Line Topology is: ~p~n",[LineTopology]),
            Neighbour = find_my_neighbour_1d(NumNodes, NumNodes, LineTopology, []),
            % io:format("~w~n", [Neighbour]),
            % register(mycounter, spawn(gossip, await_result, [0, 0])),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_line_pushsum(NumNodes, NumNodes, LineTopology, Neighbour),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);

        {fullnw, NumNodes, pushsum} when NumNodes > 0 -> 
            FullNWTopology = build_fullnw_ps(NumNodes, #{}),
            % io:format("The Full Network Topology is: ~p~n",[maps:find("Neighbour",FullNWTopology)]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_fullnw_pushsum(NumNodes, NumNodes, maps:get("Neighbour",FullNWTopology)),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Full Network Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
    
        {_, NumNodes} when NumNodes == 0 ->
            unknown
    end.

random_selection_of_living_actors_ps(Curprocess, Count, Sender_id, [{First,_,_} | Rest], Num) ->
    if Count == Num ->
        [Count,0];
    true -> 
        if First == Curprocess ->
            random_selection_of_living_actors_ps(Curprocess, Count+1, Sender_id, Rest, Num);
        true ->
            Status = is_process_alive(First),
            if Status == false ->
                random_selection_of_living_actors_ps(Curprocess, Count+1, Sender_id, Rest, Num);
            true ->
                [Count, First]
            end
        end
    end.

get_initials_value(Curprocess, [{First,Si, Wi} | Rest]) ->
    if First == Curprocess ->
        [Si, Wi];
    true ->
        get_initials_value(Curprocess, Rest)
    end.
         
listen_ps() ->
    receive
        {_, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;
        {Gossip, Sender_id, Neighbour, Pos, LineTopology, S, W, Count, connectline} ->
            [Si, Wi] = get_initials_value(self(), LineTopology),
            Snew = Si + S,
            Wnew = Wi + W,
            LineTopologyNew = lists:keyreplace(self(), 1, LineTopology, {self(),Snew, Wnew}),
            Ratio = abs((Si/Wi) - (Snew/Wnew)),
            Thresh = math:pow(10,-10),
            if Ratio =< Thresh ->
                % io:format("MY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))),
                if Val == length(LineTopology) ->
                    Sender_id ! {donedone},
                    % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                    exit(self());
                true ->
                    if Count == 3 ->
                        lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, Snew/2, Wnew/2, 0, connectline},
                        exit(self());
                    true ->
                        lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, Snew/2, Wnew/2, Count + 1, connectline}
                    end
                end;
            true ->
                % io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
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
                {Heardby,_,_} = lists:nth(Coln, Blockof),
                case is_process_alive(Heardby) of 
                    false -> 
                        Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))),
                        if Val == length(LineTopology) ->
                            % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology))), LineTopology, Snew/2, Wnew/2, Count, connectline}
                        end;
                    _ ->
                        Heardby ! {"youknowwhat", Sender_id, Neighbour, Posnew, LineTopologyNew, (Snew)/2, (Wnew)/2, Count, connectline}
                end
            end;


            {Gossip, Sender_id, Neighbour, S, W, Count, connectfullnw} ->
                [Si, Wi] = get_initials_value(self(), Neighbour),
                Snew = Si + S,
                Wnew = Wi + W,
                NeighbourNew = lists:keyreplace(self(), 1, Neighbour, {self(),Snew, Wnew}),
                Ratio = abs((Si/Wi) - (Snew/Wnew)),
                % io:format("~w ~n",[Ratio]),
                Thresh = math:pow(10,-10),
                if Ratio =< Thresh ->
                % io:format("MY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                    Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))),
                    if Val == length(Neighbour) ->
                        Sender_id ! {donedone},
                        % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                        exit(self());
                    true ->
                        if Count == 3 ->
                            lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(NeighbourNew))) ! {"youknowwhat", Sender_id, NeighbourNew ,Snew/2, Wnew/2, 0, connectfullnw},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))) ! {"youknowwhat", Sender_id, NeighbourNew, Snew/2, Wnew/2, Count + 1, connectfullnw}
                        end
                    end;
            true ->
                % io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                {Heardby,_,_} = lists:nth(1,NeighbourNew),
                case is_process_alive(Heardby) of 
                    false -> 
                        Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))),
                        if Val == length(Neighbour) ->
                            % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))) ! {"youknowwhat", Sender_id, NeighbourNew, Snew/2, Wnew/2, Count, connectfullnw}
                        end;
                    _ -> Heardby ! {"youknowwhat", Sender_id, NeighbourNew, Snew/2, Wnew/2, Count,  connectfullnw}
                end
            end
    end,
    listen_ps().

%% BUILD TOPOLOGY
build_line_pushsum(0, LineTopology, _)  ->
    LineTopology;
build_line_pushsum(NumNodes, Rest, Row) ->
    Pid = spawn(pushsum, listen_ps, []),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        io:format("",[])
    end,
    build_line_pushsum(NumNodes-1, [{Pid,NumNodes,1} | Rest], Row+1).

build_fullnw_ps(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw_ps(NumNodes, _) ->
    Record = build_line_pushsum(NumNodes, [], 1),
    build_fullnw_ps(0, Record).

%% Line Topology
find_my_neighbour_1d(0, 0, _, Neighbour) ->
    Neighbour;
find_my_neighbour_1d(NumNodes, Pos, LineTopology, Neighbour) ->
    case Pos of 
        1 -> find_my_neighbour_1d(0, 0, LineTopology, [[lists:nth(2, LineTopology)]|Neighbour]);
        NumNodes -> find_my_neighbour_1d(NumNodes, Pos-1, LineTopology, [[lists:nth(NumNodes-1, LineTopology)]|Neighbour]);
        _ -> find_my_neighbour_1d(NumNodes,Pos-1 , LineTopology, [[lists:nth(Pos-1, LineTopology),lists:nth(Pos+1, LineTopology)]| Neighbour])
    end.

you_know_what_line_pushsum(_, Pos, _, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_line_pushsum(NumNodes, Pos, LineTopology,Neighbour) when Pos == NumNodes->
    {Heardby,_,_} = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), Neighbour, Pos,  LineTopology, NumNodes, 1, 0, connectline},
    you_know_what_line_pushsum(NumNodes, 0, LineTopology,Neighbour).

you_know_what_fullnw_pushsum(_, Pos, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_fullnw_pushsum(NumNodes, Pos, FullNWTopology) when Pos == NumNodes ->
    {Heardby,_,_} = lists:nth(Pos, FullNWTopology),
    Heardby ! {"youknowwhat", self(), FullNWTopology, NumNodes, 1, 0,connectfullnw},
    you_know_what_fullnw_pushsum(NumNodes, 0, FullNWTopology).