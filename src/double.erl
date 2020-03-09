%%%-------------------------------------------------------------------
%%% @author Peter
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(double).
-author("Peter").

%% API
-export([start/0]).

start() ->
  Pid = spawn(fun double/0),
  register(double,Pid).

double() ->
  receive
    {Pid, Ref, N} ->
      Pid ! {Ref, N * 2},
      double()
  end.