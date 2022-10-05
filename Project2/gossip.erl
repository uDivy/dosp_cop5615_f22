-module(gossip).
-compile(export_all).
-define (LineTopology, []).

build_topology(Types) ->
    case Types of
        {line, NumNodes} when NumNodes > 0 ->
            LineTopology = build_line(NumNodes, []),
            io:format("The Line Topology is: ~p~n",[LineTopology]);
        {twodgrid, NumNodes} when NumNodes > 0 -> 
            Col = erlang:list_to_integer(erlang:float_to_list(math:sqrt(NumNodes),[{decimals,0}])),
            TwoDTopology = build_twodgrid(NumNodes, Col, []),
            io:format("The 2D Grid Topology is: ~p~n",[TwoDTopology]);
        {fullnw, NumNodes} when NumNodes > 0 -> 
            FullNWTopology = build_fullnw(NumNodes, #{}),
            io:format("The Full Network Topology is: ~p~n",[FullNWTopology]);
        {_, NumNodes} when NumNodes == 0 ->
            unknown
    end.

listen() ->
    receive
        bye ->
            io:format("Line closed~n", []);
        {Msg, Sender_id} -> 
            io:format("My name is ~w and I heard ~p from ~w~n",[self(), Msg, Sender_id]),
            Sender_id ! ack,
            listen()
    end.
    

build_line(0, LineTopology)  ->
    LineTopology;
build_line(NumNodes, Rest) ->
    Pid = spawn(gossip, listen, []),
    Pid ! {"Nothing", self()},
    receive
    ack -> 
        io:format("The new member in topology is: ~w~n",[Pid])
    end,
    build_line(NumNodes-1, [Pid | Rest]).


build_twodgrid(NumNodes, Col, TwoDTopology) when NumNodes =< Col->
    Record = build_line(NumNodes, []),
    [Record | TwoDTopology];
build_twodgrid(NumNodes, Col, Rest) when NumNodes >= Col ->
    Record = build_line(Col, []),
    build_twodgrid(NumNodes-Col, Col, [Record | Rest]).

build_fullnw(0, Rest) ->
    #{"Neighbour"=> Rest};
build_fullnw(NumNodes, _) ->
    Record = build_line(NumNodes, []),
    build_fullnw(0, Record).


