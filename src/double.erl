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
-export([start/0, double/1]).

start() ->
  Pid = spawn(fun double/0),
  register(double, Pid),
  Pid.

double() ->
  receive
    {Pid, Ref, N} ->
      Pid ! {Ref, N * 2},
      double()
  end.

double(T) ->
  Ref = make_ref(),
  case is_pid(whereis(double)) of
    false ->
      io:format("Process dead, trying again in 100ms"),
      timer:sleep(100),
      double(T);
    true ->
      double ! {self(), Ref, T},
      receive
        {Ref, Number} ->
          Number

      end




  end.
