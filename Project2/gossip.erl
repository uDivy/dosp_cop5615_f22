-module(gossip).
-compile(export_all).
-import(string,[concat/2]). 

build_topology(Types) ->
    case Types of
        {line, NumNodes} when NumNodes > 0 ->
            LineTopology = build_line(NumNodes, []),
            io:format("The Line Topology is: ~p~n",[LineTopology]),
            Start = ErlangSystemTime = erlang:system_time(second),
            you_know_what_line(length(LineTopology), NumNodes, LineTopology),
            End = ErlangSystemTime = erlang:system_time(second),
            io:format("Time Taken by Line Topology for ~w Nodes is: ~w seconds~n", [NumNodes, End-Start]);
        {twodgrid, NumNodes} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            TwoDTopology = build_twodgrid(NumNodes, Col, []),
            io:format("The 2D Grid Topology is: ~p~n",[TwoDTopology]),
            Start = ErlangSystemTime = erlang:system_time(second),
            % you_know_what_twod(1, 1, TwoDTopology),
            End = ErlangSystemTime = erlang:system_time(second),
            io:format("Time Taken by 2D Topology for ~w Nodes is: ~w seconds~n", [NumNodes, End-Start]);
        {fullnw, NumNodes} when NumNodes > 0 -> 
            FullNWTopology = build_fullnw(NumNodes, #{}),
            io:format("The Full Network Topology is: ~p~n",[maps:find("Neighbour",FullNWTopology)]),
            Start = ErlangSystemTime = erlang:system_time(second),
            you_know_what_fullnw(maps:get("Neighbour",FullNWTopology)),
            End = ErlangSystemTime = erlang:system_time(second),
            io:format("Time Taken by Full Network Topology for ~w Nodes is: ~w seconds~n", [NumNodes, End-Start]);
        {impthreed, NumNodes} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            ThreeDTopology = build_impthreed(NumNodes, Col, []),
            io:format("The Imperfect 3D Grid Topology is: ~p~n",[ThreeDTopology]);
        {_, NumNodes} when NumNodes == 0 ->
            unknown
    end.

listen(Count) ->
    receive
        bye ->
            io:format("Line closed~n", []),
            exit(self());
        {Msg, Sender_id} -> 
            % io:format("My name is ~w and I heard ~p from ~w and the count is ~w~n",[self(), Msg, Sender_id, Count]),
            Sender_id ! ack;
        {Gossip, Sender_id, connect} ->
            % io:format("My name is ~w and I heard ~p from ~w ~w times~n",[self(), Gossip, Sender_id, Count]),
            Sender_id ! {really, Count}
    end,
    listen(Count + 1).
    
%% BUILD TOPOLOGY
build_line(0, LineTopology)  ->
    LineTopology;
build_line(NumNodes, Rest) ->

    Str = "human" ++ integer_to_list(NumNodes),
    register(list_to_atom(Str), spawn(gossip, listen, [0])),
    list_to_atom(Str) ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        io:format("",[])
    end,
    build_line(NumNodes-1, [list_to_atom(Str) | Rest]).

%% BUILD TOPOLOGY
build_line(0, LineTopology, _)  ->
    LineTopology;
build_line(NumNodes, Rest, Row) ->
    AllowedChars = "qwertyuiopasdfghjklzxcvbnm[]\';./,{}|:<>?",

    Ranstring = lists:foldl(fun(_, Acc) ->
                    [lists:nth(rand:uniform(length(AllowedChars)),
                                AllowedChars)]
                              ++ Acc
                    end, [] , lists:seq(1, 10)),

    Str = Ranstring ++ "human" ++ integer_to_list(Row) ++ integer_to_list(NumNodes),
    register(list_to_atom(Str), spawn(gossip, listen, [0])),
    list_to_atom(Str) ! {"Nothing", self()},
    receive
    ack -> 
        % io:format("The new member in topology is: ~w~n",[Pid])
        io:format("",[])
    end,
    build_line(NumNodes-1, [list_to_atom(Str) | Rest], Row+1).


build_twodgrid(NumNodes, Col, TwoDTopology) when NumNodes =< Col->
    Record = build_line(NumNodes, [], 1),
    [Record | TwoDTopology];
build_twodgrid(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_twodgrid(NumNodes-Col, Col, [Record | Rest]).

build_fullnw(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw(NumNodes, _) ->
    Record = build_line(NumNodes, []),
    build_fullnw(0, Record).

build_impthreed(NumNodes, Col, ThreeDTopology) when NumNodes =< Col->
    Record = build_line(NumNodes, [], 1),
    [Record | ThreeDTopology];
build_impthreed(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, [], 1),
    build_impthreed(NumNodes-Col, Col, [Record | Rest]).

%% Line Topology
you_know_what_line(_, _, []) ->
    done;
you_know_what_line(NumNodes, Pos, LineTopology) when Pos == NumNodes ->
    % select a neighbour
    % tell the rumour
    % get the count of the no. of time, heard the rumour
    Heardby = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        LineTopologyNew = lists:delete(Heardby, LineTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        LineTopologyNew = LineTopology
    end
    end,
    you_know_what_line(length(LineTopologyNew), Pos-1, LineTopologyNew);
you_know_what_line(NumNodes, Pos, LineTopology) when NumNodes == 1 ->
    % select a neighbour
    % tell the rumour
    % get the count of the no. of time, heard the rumour
    Heardby = lists:nth(1, LineTopology),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        LineTopologyNew = lists:delete(Heardby, LineTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        LineTopologyNew = LineTopology
    end
    end,
    you_know_what_line(length(LineTopologyNew), 0, LineTopologyNew);

you_know_what_line(NumNodes, Pos, LineTopology) when Pos > NumNodes div 2 ->
   % select a neighbour
    % tell the rumour
    % get the count of the no. of time, heard the rumour
    Heardby = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        LineTopologyNew = lists:delete(Heardby, LineTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        LineTopologyNew = LineTopology
    end
    end,
you_know_what_line(length(LineTopologyNew), Pos-1, LineTopologyNew);

you_know_what_line(NumNodes, Pos, LineTopology) when Pos =< NumNodes div 2 ->
   % select a neighbour
    % tell the rumour
    % get the count of the no. of time, heard the rumour
    Heardby = lists:nth(Pos, LineTopology),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        LineTopologyNew = lists:delete(Heardby, LineTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        LineTopologyNew = LineTopology
    end
    end,
you_know_what_line(length(LineTopologyNew), Pos+1, LineTopologyNew).

%% FULL NW
you_know_what_fullnw([]) ->
    done;
you_know_what_fullnw(FullNWTopology)->
    Heardby = lists:nth(rand:uniform(length(FullNWTopology)),FullNWTopology),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        FullNWTopologyNew = lists:delete(Heardby, FullNWTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        FullNWTopologyNew = FullNWTopology
    end
    end,
you_know_what_fullnw(FullNWTopologyNew).

%% 2D Grid
find_neighbour_2d(row, col, directions) ->
    io:format(lists:nth(rand:uniform(length(directions)),directions)),
    [row, col].

you_know_what_twod(_, _, []) ->
    done;
you_know_what_twod(i, j, TwoDTopology)->
    Blockof = lists:nth(i, TwoDTopology),
    Heardby = lists:nth(j, Blockof),
    Heardby ! {"youknowwhat", self(), connect},
    receive
    {really, Count} ->
        io:format("Gossip heard by: ~w, ~w no. of times~n",[Heardby, Count]),
    if Count >= 10 ->
        Heardby ! bye,
        TwoDTopologyNew = lists:delete(Heardby, TwoDTopology);
        % io:format("Deleted: ~w~n",[LineTopologyNew]);
    true ->
        TwoDTopologyNew = TwoDTopology
    end
    end,
    NewAd = find_neighbour_2d(i, j, ["n", "s", "e", "w"]),
    io:format("~w~n",[NewAd]),
you_know_what_twod(lists:nth(1, NewAd), lists:nth(2, NewAd), TwoDTopologyNew).