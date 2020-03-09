%%%-------------------------------------------------------------------
%%% @author Peter
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(monitor).
-author("Peter").

%% API
-export([start/0]).

start() ->
  Pid = double:start(),
  io:format("Hello: ~p", [Pid]),
  on_error(Pid, fun(Pid, Why) ->
    io:format("pid: ~p failed with error: ~p - ~n", [Pid, Why])
                end).

on_error(Pid, On_Error) ->
  spawn(fun() ->
    Reference = monitor(process, Pid),
    io:format("Reference ~p", [Reference]),
    receive
      {'DOWN', Reference, process, _Pid, Why} ->
        demonitor(Reference),
        On_Error(Pid, Why),
        unregister(double),
        io:format("I(parent my worker ~p died(~p) with reason: ~n", [Pid, Why]),
        start()
    end
        end).
