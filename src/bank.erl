%%%-------------------------------------------------------------------
%%% @author Peter
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. mars 2020 10:02
%%%-------------------------------------------------------------------
-module(bank).
-author("Peter").

%% API
-export([start/0, balance/2, deposit/3, withdraw/3, lend/4]).

start() ->
  Pid = spawn(fun() -> bank(#{}) end),
  register(bank, Pid),
  Pid.

bank(Accounts) ->
  receive
  %%Balance
    {Pid, Ref, Account} ->
      Pid ! {Ref, maps:get(Account, Accounts, no_account)},
      bank(Accounts);
  %%Deposit
    {Pid, Ref, Account, Amount, deposit} ->
      NewAccounts = maps:put(Account, maps:get(Account, Accounts, 0) + Amount, Accounts),
      Pid ! {Ref, maps:get(Account, NewAccounts)},
      bank(NewAccounts);
  %%withdraw
    {Pid, Ref, Account, Amount, withdraw} ->
      case is_map_key(Account, Accounts) of
        false ->
          Pid ! {Ref, no_account},
          bank(Accounts);
        true ->
          NewBalanace = maps:get(Account, Accounts) - Amount,
          case NewBalanace >= 0 of
            false ->
              Pid ! {Ref, insufficient_funds},
              bank(Accounts);
            true ->
              Pid ! {Ref, NewBalanace},
              bank(maps:update(Account, NewBalanace, Accounts))
          end
      end,

      NewAccounts = maps:put(Account, maps:get(Account, Accounts, 0) - Amount, Accounts),
      Pid ! {Ref, maps:get(Account, NewAccounts)},
      bank(NewAccounts);
  %%Lend
    {Pid, Ref, From, To, Amount} when not is_map_key(From, Accounts) and not is_map_key(To, Accounts) ->
      Pid ! {Ref,{no_account, both}},
      bank(Accounts);

    {Pid, Ref, From, To, Amount} when not is_map_key(From, Accounts) or not is_map_key(To, Accounts) ->
      case is_map_key(From, Accounts) of
        false ->
          Pid ! {Ref,{no_account, From}};
        true ->
          Pid ! {Ref,{no_account, To}}
      end,
      bank(Accounts);

    {Pid, Ref, From, To, Amount} ->
      FromBalanace = maps:get(From, Accounts) - Amount,
      case FromBalanace >= 0 of
        false ->
          Pid ! {Ref, insufficient_funds},
          bank(Accounts);
        true ->
          WAccounts = maps:update(From, FromBalanace, Accounts),
          DAccounts = maps:update(To, maps:get(To, Accounts) + Amount, WAccounts),
          Pid ! {Ref, ok},
          bank(DAccounts)
      end
  end.

balance(Pid, Account) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Account},
  receive
    {Ref, Balance} ->
      Balance
  end.

deposit(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Account, Amount, deposit},
  receive
    {Ref, NewAmount} ->
      {ok, NewAmount}
  end.

withdraw(Pid, Account, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, Account, Amount, withdraw},
  receive
    {Ref, NewAmount} ->
      {ok, NewAmount}
  end.

lend(Pid, From, To, Amount) ->
  Ref = make_ref(),
  Pid ! {self(), Ref, From, To, Amount},
  receive
    {Ref, LendAnswer} ->
      LendAnswer
  end.

