%%%-------------------------------------------------------------------
%%% @author Peter
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:03
%%%-------------------------------------------------------------------
-module(gen_worker).
-author("Peter").

%% API
-export([start/2, stop/1, async/2, await/1, await_all/1]).

-callback handle_work(W :: term()) ->
  {result, Result :: term()}.


start(_Callback, 0) ->
  [];

start(Callback, Max) ->
  Pid = spawn(fun () -> Wpid = workpool(Callback, Max),
    register(wpid,Wpid)
        end),
  io:format(" Start process Pid: ~p \n",[Pid]),
  io:format(" Worker Wpid: ~p \n",[whereis(wpid)]),
  whereis(wpid).
%%  spawn(fun () ->
%%    loop(Callback)
%%    end).

workpool([H|T]) ->
  io:format("Workpool list: ~p ~p \n",[H,T]),
  receive
    {Pid, Ref} ->
      io:format("Pid banged to workpool ~p \n", [Pid]),
      Pid ! {H, Ref},
      io:format("WorkerPID sent from Pool ~p \n", [H]),
      workpool(T++ [H])
  end.

workpool(Callback, Max) ->
  Pid = spawn(fun () -> workpool(create_workpool(Callback, Max)) end),
  io:format("WoorkPool PID create: ~p \n", [Pid]),
  Pid.

create_workpool(_Callback, 0) ->
  [];
create_workpool(Callback, Max) ->
  [spawn(fun () ->
    loop(Callback)
        end) | create_workpool(Callback, Max -1)].

loop(Callback) ->
  receive
    {From, Ref, {request, Request}}  ->
      io:format("Loop ~p \n", [From]),
      case Callback:handle_work(Request) of
        {result, Response} ->
          io:format("Baning result to : ~p \n",[From]),
          io:format("Result: ~p \n",[Response]),
          From ! {response, Ref, Response},
          loop(Callback)
      end
  end.

stop(_Pid) ->
  ok.

async(Pid, W) ->
  io:format("Pid sent to async ~p  \n",[Pid]),
  io:format("Work sent to Async; ~p \n", [W]),
  Ref = make_ref(),
  Pid ! {self(), Ref, {request, W}},
  Ref.

await(Ref) ->
  io:format("await ~p \n",[self()]),
  receive
    {response, Ref, Response} ->
      %%io:format("Got response"),
      Response
    %%{response,B,C} ->
     %% io:format("Await response worng catch: ~p \n",[B])
  end.

await_all([]) ->
  [];

await_all(Refs) ->
  io:format("Await_all Refs: ~p \n", [Refs]),
  [await(Ref) || Ref <- lists:reverse(Refs)].

%%await(Ref),
  %%await_all(Refs)




