%%%-------------------------------------------------------------------
%% @doc efbsdpkg public API
%% @end
%%%-------------------------------------------------------------------

-module(efbsdpkg_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    efbsdpkg_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
