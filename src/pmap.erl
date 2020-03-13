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

ordered(Fun, List) ->
  WorkPool = gen_worker:start(?MODULE, 2),
  Refs = [gen_worker:async(WorkPool, {Fun, I}) || I <- List],
  Result = gen_worker:await_all(Refs),
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

gatherOrdered([]) ->
  [];

gatherOrdered([Pid|Pids]) ->
  receive
    {Pid, {result, R}} ->
      [R|gatherOrdered(Pids)]
  end.

handle_work({Fun, I}) ->
  {result, Fun(I)}.