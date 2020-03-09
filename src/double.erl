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
  spawn(fun doubler/0).

doubler() ->
  receive
    {Number, Pid} ->
      Pid ! Number * 2,
      doubler()
  end.