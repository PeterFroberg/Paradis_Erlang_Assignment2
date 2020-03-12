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
-export([unordered/2, unordered/3]).

unordered(F, List) ->
  Pids = [spawn_worker(F,I) || I <- List],
  gather(Pids).

unordered(F, List, MaxWorkers) when MaxWorkers < length(List)->
  {H,T} = lists:split(MaxWorkers, List),
  unordered(F, H) ++ unordered(F, T, MaxWorkers);

unordered(F, List, _MaxWorkers) ->
  unordered(F, List).

ordered(F, List, MaxWorkers)

spawn_worker(F,I) ->
  Pid = spawn(fun worker/0),
  Pid ! {self(),{work,F,I}},
  Pid.

worker() ->
  receive
    {Master, {work, F, I}} ->
      Master ! {self(), {result, F(I)}}
  end.

gather([]) ->
  [];
gather([Pid|Pids]) ->
  receive
    {Pid, {result, R}} ->
      [R|gather(Pids)]
  end.