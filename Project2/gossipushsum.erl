-module(gossipushsum).
-compile(export_all).
-import(string,[concat/2]).

%%% ************************************************** BOSS := CHOICE IS YOURS *******************************************************%%%
%% [SELECT YOUR TOPOLOGY AND NUMBER OF NODES AND ALGO(GOSSIP OR PUSHSUM)] %%

build_topology(Types) ->
    case Types of

        {line, NumNodes, gossip} when NumNodes > 0 ->
            LineTopology = build_line(NumNodes, [],1),
            % io:format("The Line Topology is: ~p~n",[LineTopology]),
            Neighbour = find_my_neighbour_1d(NumNodes, NumNodes, LineTopology, []),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_line(NumNodes, NumNodes, LineTopology, Neighbour),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
        

        {fullnw, NumNodes, gossip} when NumNodes > 0 -> 
            FullNWTopology = build_fullnw(NumNodes, #{}),
            % io:format("The Full Network Topology is: ~p~n",[maps:find("Neighbour",FullNWTopology)]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_fullnw(NumNodes, NumNodes, maps:get("Neighbour",FullNWTopology)),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Full Network Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);


        {twodgrid, NumNodes, gossip} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            TwoDTopology = build_twodgrid(NumNodes, Col, []),
            % io:format("The 2D Grid Topology is: ~p~n",[TwoDTopology]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_twod(1, 1, TwoDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by 2D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);


        {impthreed, NumNodes, gossip} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            ThreeDTopology = build_impthreed(NumNodes, Col, []),
            % io:format("The Imperfect 3D Grid Topology is: ~p~n",[ThreeDTopology]);
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_threed(1, 1, ThreeDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Imperfect 3D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);

        {line, NumNodes, pushsum} when NumNodes > 0 ->
            LineTopology = build_line_pushsum(NumNodes, [],1),
            io:format("The Line Topology is: ~p~n",[LineTopology]),
            Neighbour = find_my_neighbour_1d(NumNodes, NumNodes, LineTopology, []),
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

        {twodgrid, NumNodes, pushsum} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            TwoDTopology = build_twodgrid_ps(NumNodes, Col, []),
            % io:format("The 2D Grid Topology is: ~p~n",[TwoDTopology]),
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_twod_ps(1, 1, TwoDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by 2D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);

        {impthreed, NumNodes,pushsum} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            Row = erlang:list_to_integer(erlang:float_to_list(math:ceil(NumNodes / Col),[{decimals,0}])),
            ThreeDTopology = build_impthreed_ps(NumNodes, Col, []),
            % io:format("The Imperfect 3D Grid Topology is: ~p~n",[ThreeDTopology]);
            Start = ErlangSystemTime = erlang:system_time(millisecond),
            you_know_what_threed_ps(1, 1, ThreeDTopology, Row, Col, [], open),
            End = ErlangSystemTime = erlang:system_time(millisecond),
            io:format("Time Taken by Imperfect 3D Topology for ~w Nodes is: ~w milliseconds~n", [NumNodes, End-Start]);
    
        {_, _} ->
            unknown
    end.

%%% ************************************************** BUILD YOUR TOPOLOGY *********************************************************%%%
%% [LINE AND FULL NETWORK AND 2D GRID AND IMPERFECT 3D GRID] %%

%%% ************************************************** FOR GOSSIP ******************************************************************%%%

%%% ************************************************** LINE TOPOLOGY ***************************************************************%%%
build_line(0, LineTopology, _)  ->
    LineTopology;
build_line(NumNodes, Rest, Row) ->
    Pid = spawn(gossipushsum, listen, [0]),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        % io:format("",[])
        ignore
    end,
    build_line(NumNodes-1, [Pid | Rest], Row+1).

%%% ************************************************** FULL NETWORK ***************************************************************%%%
build_fullnw(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw(NumNodes, _) ->
    Record = build_line(NumNodes, [], 1),
    build_fullnw(0, Record).

%%% ************************************************** 2D GRID ********************************************************************%%%
build_twodgrid(NumNodes, Col, TwoDTopology) when NumNodes < Col->
    Record = build_line(Col, [], 1),
    [Record | TwoDTopology];
build_twodgrid(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_twodgrid(NumNodes-Col, Col, [Record | Rest]).

%%% ************************************************** IMPERFECT 3D GRID **********************************************************%%%
build_impthreed(NumNodes, Col, ThreeDTopology) when NumNodes =< Col->
    Record = build_line(Col, [], 1),
    [Record | ThreeDTopology];
build_impthreed(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_impthreed(NumNodes-Col, Col, [Record | Rest]).

%%% ************************************************** FOR PUSHSUM *********************************************************%%%

%%% ************************************************** LINE TOPOLOGY ***************************************************************%%%
build_line_pushsum(0, LineTopology, _)  ->
    LineTopology;
build_line_pushsum(NumNodes, Rest, Row) ->
    Pid = spawn(gossipushsum, listen_ps, []),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        % io:format("",[])
        ignore
    end,
    build_line_pushsum(NumNodes-1, [{Pid,NumNodes,1} | Rest], Row+1).

%%% ************************************************** FULL NETWORK ***************************************************************%%%
build_fullnw_ps(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw_ps(NumNodes, _) ->
    Record = build_line_pushsum(NumNodes, [], 1),
    build_fullnw_ps(0, Record).

%%% ************************************************** 2D GRID ********************************************************************%%%
build_twodgrid_ps(NumNodes, Col, TwoDTopology) when NumNodes < Col->
    Record = build_line_pushsum(Col, [], 1),
    [Record | TwoDTopology];
build_twodgrid_ps(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line_pushsum(Col, [], 1),
    build_twodgrid_ps(NumNodes-Col, Col, [Record | Rest]).

%%% ************************************************** IMPERFECT 3D GRID **********************************************************%%%
build_impthreed_ps(NumNodes, Col, ThreeDTopology) when NumNodes =< Col->
    Record = build_line_pushsum(Col, [], 1),
    [Record | ThreeDTopology];
build_impthreed_ps(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line_pushsum(Col, [], 1),
    build_impthreed_ps(NumNodes-Col, Col, [Record | Rest]).

%%% ************************************************** SUPERVISOR := LET ME KNOW ***********************************************%%%

%%% ************************************************** FOR GOSSIP **************************************************************%%%

%%% ************************************************** LINE TOPOLOGY ***************************************************************%%%
you_know_what_line(_, Pos, _, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_line(NumNodes, Pos, LineTopology,Neighbour) when Pos == NumNodes->
    Heardby = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), Neighbour, Pos,  LineTopology, connectline},
    you_know_what_line(NumNodes, 0, LineTopology,Neighbour).

%%% ************************************************** FULL NETWORK ***************************************************************%%%
you_know_what_fullnw(_, Pos, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_fullnw(NumNodes, Pos, FullNWTopology) when Pos == NumNodes ->
    Heardby = lists:nth(Pos, FullNWTopology),
    Heardby ! {"youknowwhat", self(), FullNWTopology, connectfullnw},
    you_know_what_fullnw(NumNodes, 0, FullNWTopology).

%%% ************************************************** 2D GRID ********************************************************************%%%
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

%%% ************************************************** IMPERFECT 3D GRID **********************************************************%%%
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

%%% ************************************************** FOR PUSHSUM *********************************************************%%%

%%% ************************************************** LINE TOPOLOGY ***************************************************************%%%
you_know_what_line_pushsum(_, Pos, _, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_line_pushsum(NumNodes, Pos, LineTopology,Neighbour) when Pos == NumNodes->
    {Heardby,_,_} = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), Neighbour, Pos,  LineTopology, NumNodes, 1, 0, connectline},
    you_know_what_line_pushsum(NumNodes, 0, LineTopology,Neighbour).

%%% ************************************************** FULL NETWORK ***************************************************************%%%
you_know_what_fullnw_pushsum(_, Pos, _) when Pos == 0 ->
    receive
        {donedone} ->
            done
    end;
you_know_what_fullnw_pushsum(NumNodes, Pos, FullNWTopology) when Pos == NumNodes ->
    {Heardby,_,_} = lists:nth(Pos, FullNWTopology),
    Heardby ! {"youknowwhat", self(), FullNWTopology, NumNodes, 1, 0,connectfullnw},
    you_know_what_fullnw_pushsum(NumNodes, 0, FullNWTopology).

%%% ************************************************** 2D GRID ********************************************************************%%%
you_know_what_twod_ps(_, _, _, _, _, _, close) ->
    receive
        {donedone} ->
            done
    end;
you_know_what_twod_ps(Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, open)->
    Blockof = lists:nth(Row, TwoDTopology),
    {Heardby,_,_} = lists:nth(Col, Blockof),
    Heardby ! {"youknowwhat", self(), Row, Col, TwoDTopology, lists:flatten(TwoDTopology), MaxRow, MaxCol, Exclude, Heardby, 1, 1, 0, connect2d},
    you_know_what_twod_ps(Row, Col, TwoDTopology, MaxRow, MaxCol, Exclude, close).

%%% ************************************************** IMPERFECT 3D GRID **********************************************************%%%
you_know_what_threed_ps(_, _, _, _, _, _, close) ->
    receive
        {donedone} ->
            done
    end;
you_know_what_threed_ps(Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, open)->
    Blockof = lists:nth(Row, ThreeDTopology),
    {Heardby,_,_} = lists:nth(Col, Blockof),
    Heardby ! {"youknowwhat", self(), Row, Col, ThreeDTopology, lists:flatten(ThreeDTopology), MaxRow, MaxCol, Exclude, Heardby, 1, 1, 0, connect3d},
    you_know_what_threed_ps(Row, Col, ThreeDTopology, MaxRow, MaxCol, Exclude, close).

%%% ************************************************** ACTORS := I KNOW **********************************************************%%%

%%% ************************************************** FOR GOSSIP ****************************************************************%%%
listen(Count) ->
    receive
        {_, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;
        {Gossip, Sender_id, Neighbour, Pos, LineTopology, connectline} ->
            if Count > 10 ->
                Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))),
                if Val == length(LineTopology) ->
                    Sender_id ! {donedone},
                    exit(self());
                true ->
                    lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {Gossip, Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline},
                    exit(self())
                end;
            true ->
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
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))) ! {Gossip, Sender_id, Neighbour, lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, LineTopology, length(LineTopology))), LineTopology, connectline}
                        end;
                    _ -> Heardby ! {Gossip, Sender_id, Neighbour, Posnew, LineTopology, connectline}
                end
            end;

        {Gossip, Sender_id, Neighbour, connectfullnw} ->
        if Count > 10 ->
            Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))),
            if Val == length(Neighbour) ->
                Sender_id ! {donedone},
                exit(self());
            true ->
                lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))) ! {Gossip, Sender_id, Neighbour, connectfullnw},
                exit(self())
            end;
        true ->
            Heardby = lists:nth(rand:uniform(length(Neighbour)),Neighbour),
            case is_process_alive(Heardby) of 
                false -> 
                    Val = lists:nth(1,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))),
                    if Val == length(Neighbour) ->
                        Sender_id ! {donedone},
                        exit(self());
                    true ->
                        lists:nth(2,random_selection_of_living_actors(self(), 1, Sender_id, Neighbour, length(Neighbour))) ! {Gossip, Sender_id, Neighbour,  connectfullnw}
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

%%% ************************************************** FOR PUSHSUM ****************************************************************%%%
listen_ps() ->
    receive
        {_, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;

            {Gossip, Sender_id, Neighbour, Pos, LineTopology, S, W, Count, connectline} ->
            [Si, Wi] = get_initials_value(self(), LineTopology),
            Snew = Si + S,
            Wnew = Wi + W,
            LineTopologyNew = lists:keyreplace(self(), 1, LineTopology, {self(),Snew/2, Wnew/2}),
            Ratio = abs((Si/Wi) - (Snew/Wnew)),
            Thresh = math:pow(10,-10),
            if Ratio =< Thresh ->
                if Count == 3 ->
                    [V, H] = random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology)),
                    H ! {Gossip, Sender_id, Neighbour, V, LineTopology, Snew/2, Wnew/2, Count, connectline},    
                    exit(self());
                true ->
                    self() ! {Gossip, Sender_id, Neighbour, Pos, LineTopology, Snew/2, Wnew/2, Count + 1, connectline}
                end;
            true ->
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
                        [Val, Heardbyme] = random_selection_of_living_actors_ps(self(), 1, Sender_id, LineTopologyNew, length(LineTopology)),
                        if Val == length(LineTopology) ->
                            Sender_id ! {donedone},
                            exit(self());
                        true ->
                            Heardbyme ! {Gossip, Sender_id, Neighbour, Val, LineTopology, Snew/2, Wnew/2, Count, connectline}
                        end;
                    _ ->      
                        Heardby ! {Gossip, Sender_id, Neighbour, Posnew, LineTopology, Snew/2, Wnew/2, Count, connectline}
                end
            end;

        {Gossip, Sender_id, Neighbour, S, W, Count, connectfullnw} ->
            [Si, Wi] = get_initials_value(self(), Neighbour),
            Snew = Si + S,
            Wnew = Wi + W,
            NeighbourNew = lists:keyreplace(self(), 1, Neighbour, {self(),Snew/2, Wnew/2}),
            Ratio = abs((Si/Wi) - (Snew/Wnew)),
            Thresh = math:pow(10,-10),
            if Ratio =< Thresh ->
                Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))),
                if Val == length(Neighbour) ->
                    Sender_id ! {donedone},
                    exit(self());
                true ->
                    if Count == 3 ->
                        lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(NeighbourNew))) ! {Gossip, Sender_id, NeighbourNew ,Snew/2, Wnew/2, 0, connectfullnw},
                        exit(self());
                    true ->
                        lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))) ! {Gossip, Sender_id, NeighbourNew, Snew/2, Wnew/2, Count + 1, connectfullnw}
                    end
                end;
        true ->
            {Heardby,_,_} = lists:nth(1,NeighbourNew),
            case is_process_alive(Heardby) of 
                false -> 
                    Val = lists:nth(1,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))),
                    if Val == length(Neighbour) ->
                        Sender_id ! {donedone},
                        exit(self());
                    true ->
                        lists:nth(2,random_selection_of_living_actors_ps(self(), 1, Sender_id, NeighbourNew, length(Neighbour))) ! {"youknowwhat", Sender_id, NeighbourNew, Snew/2, Wnew/2, Count, connectfullnw}
                    end;
                _ -> Heardby ! {Gossip, Sender_id, NeighbourNew, Snew/2, Wnew/2, Count,  connectfullnw}
            end
        end;

        {Gossip, Sender_id, Row, Col, TwoDTopology, TwoDTopologyflat, MaxRow, MaxCol, Exclude, Heardby, S, W, Count, connect2d} ->
            [Si, Wi] = get_initials_value(self(), TwoDTopologyflat),
            Snew = Si + S,
            Wnew = Wi + W,
            TwoDTopologyflatNew = lists:keyreplace(self(), 1, TwoDTopologyflat, {self(),Snew/2, Wnew/2}),
            Ratio = abs((Si/Wi) - (Snew/Wnew)),
            Thresh = math:pow(10,-10),
            if Ratio =< Thresh ->  
                [Row1, Col1] = random_selection_of_living_actors_2d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                if Row1 == 0 ->
                    Sender_id ! {donedone};
                true ->
                    if Count == 3
                            ->
                            [Row2, Col2] = random_selection_of_living_actors_2d_ps(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                            if Row2 == 0 ->
                                Sender_id ! {donedone};
                            true -> 
                                {Sendit,_,_} = lists:nth(Col2, lists:nth(Row2, TwoDTopology)),
                                Sendit ! {Gossip, Sender_id, Row2, Col2, TwoDTopology, TwoDTopologyflatNew, MaxRow, MaxCol, [self() | Exclude], Heardby, Snew/2, Wnew/2, 0, connect2d},    
                                exit(self())
                            end;
                    true ->
                            {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, TwoDTopology)),
                            Sendit ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, TwoDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count + 1, connect2d}
                    end
                end;
            true ->
                Val = lists:member(self(), Exclude),
                if Val == true ->
                    [Row1, Col1] = random_selection_of_living_actors_2d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                    if Row1 == 0 ->
                        Sender_id ! {donedone};
                    true ->
                        {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, TwoDTopology)),
                        Sendit ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, TwoDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count, connect2d}
                    end;
                true ->
                    [Row1, Col1] = random_selection_of_living_actors_2d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, TwoDTopology),
                    if Row1 == 0 ->
                        Sender_id ! {donedone};
                    true ->
                        {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, TwoDTopology)),
                        Sendit ! {Gossip, Sender_id, Row1, Col1, TwoDTopology, TwoDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count, connect2d}
                    end
                end
            end;

            {Gossip, Sender_id, Row, Col, ThreeDTopology, ThreeDTopologyflat,  MaxRow, MaxCol, Exclude, Heardby, S, W, Count, connect3d} ->
                [Si, Wi] = get_initials_value(self(), ThreeDTopologyflat),
                Snew = Si + S,
                Wnew = Wi + W,
                ThreeDTopologyflatNew = lists:keyreplace(self(), 1, ThreeDTopologyflat, {self(),Snew/2, Wnew/2}),
                Ratio = abs((Si/Wi) - (Snew/Wnew)),
                % io:format("~w ~n",[Ratio]),
                Thresh = math:pow(10,-10),
                if Ratio =< Thresh ->
                    [Row1, Col1] = random_selection_of_living_actors_3d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                if Row1 == 0 ->
                    Sender_id ! {donedone};
                true ->
                    if Count == 3
                            ->
                            [Row2, Col2] = random_selection_of_living_actors_3d_ps(Row, Col, [self() | Exclude], MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                            if Row2 == 0 ->
                                Sender_id ! {donedone};
                            true -> 
                                {Sendit,_,_} = lists:nth(Col2, lists:nth(Row2, ThreeDTopology)),
                                Sendit ! {Gossip, Sender_id, Row2, Col2, ThreeDTopology, ThreeDTopologyflatNew, MaxRow, MaxCol, [self() | Exclude], Heardby, Snew/2, Wnew/2, 0, connect3d},    
                                exit(self())
                            end;
                    true ->
                            {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, ThreeDTopology)),
                            Sendit ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, ThreeDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count + 1, connect3d}
                    end
                end;
            true ->
                Val = lists:member(self(), Exclude),
                if Val == true ->
                    [Row1, Col1] = random_selection_of_living_actors_3d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                    if Row1 == 0 ->
                        Sender_id ! {donedone};
                    true ->
                        {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, ThreeDTopology)),
                        Sendit ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, ThreeDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count, connect3d}
                    end;
                true ->
                    [Row1, Col1] = random_selection_of_living_actors_3d_ps(Row, Col, Exclude, MaxRow*MaxCol, MaxRow, MaxCol, ThreeDTopology),
                    if Row1 == 0 ->
                        Sender_id ! {donedone};
                    true ->
                        {Sendit,_,_} = lists:nth(Col1, lists:nth(Row1, ThreeDTopology)),
                        Sendit ! {Gossip, Sender_id, Row1, Col1, ThreeDTopology, ThreeDTopologyflatNew, MaxRow, MaxCol, Exclude, Heardby, Snew/2, Wnew/2, Count, connect3d}
                    end
                end
            end
    end,
    listen_ps().


%%% **************************************************  UTILITY FUNCTIONS ************************************************************%%%

%%% **************************************** TO SUPPORT RANDOM SELECTION OF LIVING ACTORS ********************************************%%%

%%% ******************************************************* FOR GOSSIP ***************************************************************%%%
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

%%% ******************************************************* FOR PUSHSUM ***************************************************************%%%
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
    
    random_selection_of_living_actors_2d_ps(Row, Col, Exclude, Totnum, MaxRow, MaxCol, TwoDTopology) ->
        if length(Exclude) == Totnum ->
            [0, 0];
        true ->
            NewAd = find_neighbour_2d(Row, Col, look, MaxRow, MaxCol),
            {Pid, _, _} = lists:nth(lists:nth(2, NewAd), lists:nth(lists:nth(1, NewAd), TwoDTopology)),
            Val = lists:member(Pid, Exclude),
            if Val == true ->
                random_selection_of_living_actors_2d_ps(lists:nth(1, NewAd), lists:nth(2, NewAd), Exclude, Totnum, MaxRow, MaxCol, TwoDTopology);
            true ->
                [lists:nth(1, NewAd),lists:nth(2, NewAd)]
            end
        end.
    
    random_selection_of_living_actors_3d_ps(Row, Col, Exclude, Totnum, MaxRow, MaxCol, ThreeDTopology) ->
        if length(Exclude) == Totnum ->
            [0, 0];
        true ->
            NewAd = find_neighbour_3d(Row, Col, look, MaxRow, MaxCol),
            {Pid, _, _} = lists:nth(lists:nth(2, NewAd), lists:nth(lists:nth(1, NewAd), ThreeDTopology)),
            Val = lists:member(Pid, Exclude),
            if Val == true ->
                random_selection_of_living_actors_3d_ps(lists:nth(1, NewAd), lists:nth(2, NewAd), Exclude, Totnum, MaxRow, MaxCol, ThreeDTopology);
            true ->
                [lists:nth(1, NewAd),lists:nth(2, NewAd)]
            end
        end.


%%% ************************************************** FIND YOUR NEIGHOBOUR **********************************************************%%%

%%% ************************************************* FOR GOSSIP AND PUSHSUM **********************************************************%%%
find_my_neighbour_1d(0, 0, _, Neighbour) ->
    Neighbour;
find_my_neighbour_1d(NumNodes, Pos, LineTopology, Neighbour) ->
    case Pos of 
        1 -> find_my_neighbour_1d(0, 0, LineTopology, [[lists:nth(2, LineTopology)]|Neighbour]);
        NumNodes -> find_my_neighbour_1d(NumNodes, Pos-1, LineTopology, [[lists:nth(NumNodes-1, LineTopology)]|Neighbour]);
        _ -> find_my_neighbour_1d(NumNodes,Pos-1 , LineTopology, [[lists:nth(Pos-1, LineTopology),lists:nth(Pos+1, LineTopology)]| Neighbour])
    end.

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

%%% ********************************************** GET THE CURREST SUM AND WEIGHT *****************************************************%%%

%%% ******************************************************* FOR PUSHSUM ***************************************************************%%%
        get_initials_value(Curprocess, [{First,Si, Wi} | Rest]) ->
            if First == Curprocess ->
                [Si, Wi];
            true ->
                get_initials_value(Curprocess, Rest)
            end.