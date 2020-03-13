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
  spawn(fun () ->
    loop(Callback)
    end).

loop(Callback) ->
  receive
    {From, Ref, {request, Request}}  ->
      case Callback:handle_work(Request) of
        {result, Response} ->
          From ! {response, Ref, Response},
          loop(Callback)
      end
  end.

stop(Pid) ->
  ok.

async(Pid, W) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, {request, W}},
  Ref.

await(Ref) ->
  receive
    {response, Ref, Response} ->
      Response
  end.

await_all([]) ->
  [];

await_all(Refs) ->
  [await(Ref) || Ref <- Refs].

%%await(Ref),
  %%await_all(Refs)


