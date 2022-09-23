-module(server).
-compile(export_all).



for_run(0,_,_) ->  
        io:fwrite("All remote workers are spawned now:: Bye!!~n");


for_run(Worker, KValue, Workload) when Worker > 0 ->

    Workload_Dist = Workload/2,
    Pid_Remote = spawn('node2@192.168.0.15', client, run, []),
    Pid_Remote ! {self(), {KValue, Workload_Dist, generate_bitcoin}},
    for_run(Worker-1,KValue, Workload).

run() ->
   {ok, KValue} = io:read("Please insert the Number of Zeroes: "),
   for_run(8, KValue, 20).