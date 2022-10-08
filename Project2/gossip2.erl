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
            you_know_what_line(NumNodes, NumNodes, LineTopology, Neighbour),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
        

        {fullnw, NumNodes} when NumNodes > 0 -> 
            FullNWTopology = build_fullnw(NumNodes, #{}),
            % io:format("The Full Network Topology is: ~p~n",[maps:find("Neighbour",FullNWTopology)]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_fullnw(NumNodes, NumNodes, maps:get("Neighbour",FullNWTopology)),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Full Network Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);


        {twodgrid, NumNodes} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            TwoDTopology = build_twodgrid(NumNodes, Col, []),
            % io:format("The 2D Grid Topology is: ~p~n",[TwoDTopology]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_twod(1, 1, TwoDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by 2D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);


        {impthreed, NumNodes} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            ThreeDTopology = build_impthreed(NumNodes, Col, []),
            % io:format("The Imperfect 3D Grid Topology is: ~p~n",[ThreeDTopology]);
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_threed(1, 1, ThreeDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Imperfect 3D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);

    
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

random_selection_of_living_actors_2d(Row, Col, Exclude, Totnum, MaxRow, MaxCol, TwoDTopology) ->
    if length(Exclude) == Totnum ->
        [0, 0];
    true ->
        NewAd = find_neighbour_2d(Row, Col, look, MaxRow, MaxCol),
        Val = lists:member(lists:nth(lists:nth(2, NewAd), lists:nth(lists:nth(1, NewAd), TwoDTopology)), Exclude),
        if Val == true ->
            random_selection_of_living_actors_2d(lists:nth(1, NewAd), lists:nth(2, NewAd), Exclude, Totnum, MaxRow, MaxCol, TwoDTopology);
        true ->
            [lists:nth(1, NewAd),lists:nth(2, NewAd)]
        end
    end.

random_selection_of_living_actors_3d(Row, Col, Exclude, Totnum, MaxRow, MaxCol, ThreeDTopology) ->
    if length(Exclude) == Totnum ->
        [0, 0];
    true ->
        NewAd = find_neighbour_3d(Row, Col, look, MaxRow, MaxCol),
        Val = lists:member(lists:nth(lists:nth(2, NewAd), lists:nth(lists:nth(1, NewAd), ThreeDTopology)), Exclude),
        if Val == true ->
            random_selection_of_living_actors_3d(lists:nth(1, NewAd), lists:nth(2, NewAd), Exclude, Totnum, MaxRow, MaxCol, ThreeDTopology);
        true ->
            [lists:nth(1, NewAd),lists:nth(2, NewAd)]
        end
    end.
         
    
listen(Count) ->
    receive
        {Msg, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;
        {Gossip, Sender_id, Neighbour, Pos, LineTopology, connectline} ->
            if Count > 10 ->
                % io:format("MY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))),
                if Val == length(LineTopology) ->
                    Sender_id ! {donedone},
                    % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                    exit(self());
                true ->
                    lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline},
                    exit(self())
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
                Heardby = lists:nth(Coln, Blockof),
                case is_process_alive(Heardby) of 
                    false -> 
                        Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))),
                        if Val == length(LineTopology) ->
                            % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {"youknowwhat", Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline}
                        end;
                    _ -> Heardby ! {"youknowwhat", Sender_id, Neighbour, Posnew, LineTopology, connectline}
                end
            end;

            {Gossip, Sender_id, Neighbour, connectfullnw} ->
            if Count > 10 ->
                % io:format("MY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))),
                if Val == length(Neighbour) ->
                    Sender_id ! {donedone},
                    % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                    exit(self());
                true ->
                    lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))) ! {"youknowwhat", Sender_id, Neighbour, connectfullnw},
                    exit(self())
                end;
            true ->
                % io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                Heardby = lists:nth(rand:uniform(length(Neighbour)),Neighbour),
                case is_process_alive(Heardby) of 
                    false -> 
                        Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))),
                        if Val == length(Neighbour) ->
                            % io:format("MYY name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))) ! {"youknowwhat", Sender_id, Neighbour,  connectfullnw}
                        end;
                    _ -> Heardby ! {"youknowwhat", Sender_id, Neighbour, connectfullnw}
                end
            end;

            {Gossip, Sender_id, Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d} ->
                    if Count > 10 ->
                        [Row1, Col1] = random_selection_of_living_actors_2d(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                        if Row1 == 0 ->
                            Sender_id ! {donedone};
                        true ->
                            lists:nth(Col1, lists:nth(Row1, TwoDTopology)) ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, MaxRow, MaxCol, [self() | Exclude], Heardby, connect2d},
                            exit(self())
                        end;
                    true ->
                        Val = lists:member(self(), Exclude),
                        if Val == true ->
                            [Row1, Col1] = random_selection_of_living_actors_2d(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                            if Row1 == 0 ->
                                Sender_id ! {donedone};
                            true ->
                                lists:nth(Col1, lists:nth(Row1, TwoDTopology)) ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d}
                            end;
                        true ->
                            [Row1, Col1] = random_selection_of_living_actors_2d(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                            if Row1 == 0 ->
                                Sender_id ! {donedone};
                            true ->
                                lists:nth(Col1, lists:nth(Row1, TwoDTopology)) ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d}
                            end
                        end
                    end;



                    {Gossip, Sender_id, Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, Heardby, connect3d} ->
                    if Count > 10 ->
                        [Row1, Col1] = random_selection_of_living_actors_3d(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                        if Row1 == 0 ->
                            Sender_id ! {donedone};
                        true ->
                            lists:nth(Col1, lists:nth(Row1, ThreeDTopology)) ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, MaxRow, MaxCol, [self() | Exclude], Heardby, connect2d},
                            exit(self())
                        end;
                    true ->
                        Val = lists:member(self(), Exclude),
                        if Val == true ->
                            [Row1, Col1] = random_selection_of_living_actors_3d(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                            if Row1 == 0 ->
                                Sender_id ! {donedone};
                            true ->
                                lists:nth(Col1, lists:nth(Row1, ThreeDTopology)) ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d}
                            end;
                        true ->
                            [Row1, Col1] = random_selection_of_living_actors_3d(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                            if Row1 == 0 ->
                                Sender_id ! {donedone};
                            true ->
                                lists:nth(Col1, lists:nth(Row1, ThreeDTopology)) ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d}
                            end
                        end
                    end
    end,
    listen(Count+1).

%% BUILD TOPOLOGY
build_line(0, LineTopology, _)  ->
    LineTopology;
build_line(NumNodes, Rest, Row) ->
    Pid = spawn(gossip2, listen, [0]),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        io:format("",[])
    end,
    build_line(NumNodes-1, [Pid | Rest], Row+1).

build_fullnw(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw(NumNodes, _) ->
    Record = build_line(NumNodes, [], 1),
    build_fullnw(0, Record).

build_twodgrid(NumNodes, Col, TwoDTopology) when NumNodes < Col->
    Record = build_line(Col, [], 1),
    [Record | TwoDTopology];
build_twodgrid(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_twodgrid(NumNodes-Col, Col, [Record | Rest]).

build_impthreed(NumNodes, Col, ThreeDTopology) when NumNodes =< Col->
    Record = build_line(Col, [], 1),
    [Record | ThreeDTopology];
build_impthreed(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_impthreed(NumNodes-Col, Col, [Record | Rest]).

%% Line Topology
find_my_neighbour_1d(0, 0, _, Neighbour) ->
    Neighbour;
find_my_neighbour_1d(NumNodes, Pos, LineTopology, Neighbour) ->
    case Pos of 
        1 -> find_my_neighbour_1d(0, 0, LineTopology, [[lists:nth(2, LineTopology)]|Neighbour]);
        NumNodes -> find_my_neighbour_1d(NumNodes, Pos-1, LineTopology, [[lists:nth(NumNodes-1, LineTopology)]|Neighbour]);
        _ -> find_my_neighbour_1d(NumNodes,Pos-1 , LineTopology, [[lists:nth(Pos-1, LineTopology),lists:nth(Pos+1, LineTopology)]| Neighbour])
    end.

you_know_what_line(_, Pos, _, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_line(NumNodes, Pos, LineTopology,Neighbour) when Pos == NumNodes->
    Heardby = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), Neighbour, Pos,  LineTopology, connectline},
    you_know_what_line(NumNodes, 0, LineTopology,Neighbour).

you_know_what_fullnw(_, Pos, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_fullnw(NumNodes, Pos, FullNWTopology) when Pos == NumNodes ->
    Heardby = lists:nth(Pos, FullNWTopology),
    Heardby ! {"youknowwhat", self(), FullNWTopology, connectfullnw},
    you_know_what_fullnw(NumNodes, 0, FullNWTopology).


%% 2D Grid
find_neighbour_2d(Rownew, Colnew, yes, _, _) ->
    [Rownew, Colnew];
find_neighbour_2d(Row, Col, look, MaxRow, MaxCol) ->
    Arrow = rand:uniform(8),
    case Arrow of 
        1 ->
            if Row - 1  == 0 ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_2d(Row-1, Col, yes, MaxRow, MaxCol)
            end;
        2 -> 
            if Row + 1  > MaxRow ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_2d(Row+1, Col, yes, MaxRow, MaxCol)
            end;
        3 -> 
            if Col + 1  > MaxCol ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_2d(Row, Col+1, yes, MaxRow, MaxCol)
            end;
        4 -> 
            if Col - 1  == 0 ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_2d(Row, Col-1, yes, MaxRow, MaxCol)
            end;
        5 ->
            if Row - 1  /= 0 ->
                if Col + 1 < MaxCol -> 
                    find_neighbour_2d(Row-1, Col+1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
            end;
        6 -> 
            if Row + 1  < MaxRow ->
                if Col + 1 < MaxCol -> 
                    find_neighbour_2d(Row+1, Col+1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
            end;
        7 -> 
            if Row + 1  < MaxRow ->
                if Col - 1 /= 0 -> 
                    find_neighbour_2d(Row+1, Col-1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
            end;
        8 -> 
            if Row - 1  /= 0 ->
                if Col - 1 /= 0 -> 
                    find_neighbour_2d(Row-1, Col-1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_2d(Row, Col, look, MaxRow, MaxCol)
            end
    end.

you_know_what_twod(_, _, _, _, _, _, close) ->
    receive
        {donedone} ->
            done
    end;
you_know_what_twod(Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, open)->
    Blockof = lists:nth(Row, TwoDTopology),
    Heardby = lists:nth(Col, Blockof),
    Heardby ! {"youknowwhat", self(), Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, Heardby, connect2d},
    you_know_what_twod(Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, close).

%% 3D
%% 3D Grid
find_neighbour_3d(Rownew, Colnew, yes, _, _) ->
    [Rownew, Colnew];
find_neighbour_3d(Row, Col, look, MaxRow, MaxCol) ->
    Arrow = rand:uniform(9),
    case Arrow of 
        1 ->
            if Row - 1  == 0 ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_3d(Row-1, Col, yes, MaxRow, MaxCol)
            end;
        2 -> 
            if Row + 1  > MaxRow ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_3d(Row+1, Col, yes, MaxRow, MaxCol)
            end;
        3 -> 
            if Col + 1  > MaxCol ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_3d(Row, Col+1, yes, MaxRow, MaxCol)
            end;
        4 -> 
            if Col - 1  == 0 ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol);
            true ->
                find_neighbour_3d(Row, Col-1, yes, MaxRow, MaxCol)
            end;
        5 ->
            if Row - 1  /= 0 ->
                if Col + 1 < MaxCol -> 
                    find_neighbour_3d(Row-1, Col+1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
            end;
        6 -> 
            if Row + 1  < MaxRow ->
                if Col + 1 < MaxCol -> 
                    find_neighbour_3d(Row+1, Col+1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
            end;
        7 -> 
            if Row + 1  < MaxRow ->
                if Col - 1 /= 0 -> 
                    find_neighbour_3d(Row+1, Col-1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
            end;
        8 -> 
            if Row - 1  /= 0 ->
                if Col - 1 /= 0 -> 
                    find_neighbour_3d(Row-1, Col-1, yes, MaxRow, MaxCol);
                true ->
                    find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
                end;
            true ->
                find_neighbour_3d(Row, Col, look, MaxRow, MaxCol)
            end;
        9 ->
            Rown = rand:uniform(MaxRow),
            Coln = rand:uniform(MaxCol),
            find_neighbour_3d(Rown, Coln, yes, MaxRow, MaxCol)
    end.
    
you_know_what_threed(_, _, _, _, _, _, close) ->
    receive
        {donedone} ->
            done
    end;
you_know_what_threed(Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, open)->
    Blockof = lists:nth(Row, ThreeDTopology),
    Heardby = lists:nth(Col, Blockof),
    Heardby ! {"youknowwhat", self(), Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, Heardby, connect3d},
    you_know_what_threed(Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, close).