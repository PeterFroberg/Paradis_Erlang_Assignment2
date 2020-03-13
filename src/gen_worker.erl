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
  Pid = spawn(fun () -> workpool(Callback, Max) end),
  Pid.
%%  spawn(fun () ->
%%    loop(Callback)
%%    end).

workpool([H|T]) ->
  receive
    {Pid} ->
      Pid ! H,
      workpool([T|H])
  end.

workpool(Callback, Max) ->
  spawn(fun () -> workpool(create_workpool(Callback, Max)) end).

create_workpool(_Callback, 0) ->
  [];
create_workpool(Callback, Max) ->
  [spawn(fun () ->
    loop(Callback)
        end) | create_workpool(Callback, Max -1)].

loop(Callback) ->
  receive
    {From, Ref, {request, Request}}  ->
      io:format("Loop ~p", [From]),
      case Callback:handle_work(Request) of
        {result, Response} ->
          From ! {response, Ref, Response},
          loop(Callback)
      end
  end.

stop(_Pid) ->
  ok.

async(Pid, W) ->
  io:format("async ~p  ",[W]),
  Ref = make_ref(),
  Pid ! {self(), Ref, {request, W}},
  Ref.

await(Ref) ->
  io:format("await ~p",[self()]),
  receive
    {response, Ref, Response} ->
      Response;
    {response,B,C} ->
      io:format("~p",[B])
  end.

await_all([]) ->
  [];

await_all(Refs) ->
  [await(Ref) || Ref <- Refs].

%%await(Ref),
  %%await_all(Refs)




