%%%-------------------------------------------------------------------
%%% @author Peter
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(pmap).
-author("Peter").

%% API
-export([unordered/2, unordered/3, ordered/2 ,ordered/3, handle_work/1]).
-behavior(gen_worker).

unordered(F, List) ->
  [spawn_worker(F,I) || I <- List],
  gather(length(List)).

unordered(F, List, MaxWorkers) when MaxWorkers < length(List)->
  {H,T} = lists:split(MaxWorkers, List),
  unordered(F, H) ++ unordered(F, T, MaxWorkers);

unordered(F, List, _MaxWorkers) ->
  unordered(F, List).

generateRefs(_WorkPool, [], _Fun, Refs) ->
  Refs;

generateRefs(WorkPool, [H|T], Fun, Refs) ->
  %%io:format("Inside getWorkerPid"),
%%  io:format("List to work on: ~p ~p \n", [H, T]),
%%  io:format("Refs: ~p \n",[Refs]),
  Ref = make_ref(),
  WorkPool ! {self(), Ref},
  receive
    {Pid, Ref} ->
      NewRef = gen_worker:async(Pid, {H, Fun}),
      %%io:format("New Ref: ~p \n", [NewRef]),
      generateRefs(WorkPool, T, Fun, [NewRef|Refs])
  end.




ordered(Fun, List) ->
  WorkPool = gen_worker:start(?MODULE, 2),
  unregister(wpid),
 %% io:format("Workpool process: ~p \n",[WorkPool]),
  Refs = generateRefs(WorkPool, List, Fun, []),
 %% io:format("Returnd from getWorkerPid: ~p \n",[Refs]),
  %%io:format("GetWorked response: ~p \n" ,[WorkerPID]),
  %%Refs = [gen_worker:async(WorkerPID, {Fun, I}) || I <- List],
  %%Refs = [gen_worker:async(getWorkerPid(WorkPool), {Fun, I}) || I <- List],

%%  Refs = [gen_worker:async((fun() -> WorkPool ! {self()},
%%    receive
%%      {Pid} ->
%%        Pid
%%    end end), {Fun, I}) || I <- List],
  Result = gen_worker:await_all(Refs),
 %% io:format("RESULTAT: ~p \n",[Result]),
  Result.

  %%Pids = [spawn_worker(F, I) || I <- List],
  %%gatherOrdered(Pids).

ordered(F, List, MaxWorkers) when MaxWorkers < length(List) ->
  {H,T} = lists:split(MaxWorkers, List),
  ordered(F, H) ++ ordered(F, T, MaxWorkers);

ordered(F, List, _MaxWorkers) ->
  ordered(F, List).

spawn_worker(F,I) ->
  Pid = spawn(fun worker/0),
  Pid ! {self(),{work,F,I}},
  Pid.

worker() ->
  receive
    {Master, {work, F, I}} ->
      %%timer:sleep(rand:uniform(1000)),
      Master ! {self(), {result, F(I)}}
  end.

gather(0) ->
  [];
gather(Index) ->
  receive
    {_Pid,{result, R}} ->
      [R|gather(Index -1)]
  end.

%%gatherOrdered([]) ->
%%  [];
%%
%%gatherOrdered([Pid|Pids]) ->
%%  receive
%%    {Pid, {result, R}} ->
%%      [R|gatherOrdered(Pids)]
%%  end.

handle_work({I, Fun}) ->
  %%io:format("Work to handle -Fun, I - : ~p , ~p \n" ,[Fun ,I]),
  {result, Fun(I)}.