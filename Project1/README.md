# dosp_cop5615_f22
This repository is to manage the projects for DOSP.

Reference: 
fprof: https://medium.com/erlang-battleground/erlang-otp-profiling-fprof-b3a1b92e43e3
fprof: https://medium.com/mr-dops/profiling-erlang-code-with-fprof-5f092619bff1 
eprof: https://medium.com/erlang-battleground/erlang-otp-profiling-eprof-f263c9a523f3 

Step to run:
(fprof)
fprof:apply(bitcoin_new,run,[]).
fprof:profile().
fprof:analyse([{dest, "./application.analysis"}]).

(eprof)
{ok, Pid} = eprof:start().
ok = eprof:log("log.analyze").
{ok, Result} = eprof:profile([Pid], bitcoin_new, run, []).
eprof:analyze().
Result.

erl -name divy_node@10.136.35.160 -setcookie 'mycookie'.