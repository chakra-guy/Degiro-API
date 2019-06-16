defmodule Degiro do
  use GenServer
  alias Degiro.Api

  # Degiro.login("username", "********") |> Degiro.get_account_info

  @moduledoc """
  Documentation for Degiro.
  """

  # CLIENT API

  @opaque account :: pid
  @opaque username :: string
  @opaque password :: string

  @spec login(username, password) :: account
  def login(username, password) do
    {:ok, account} = GenServer.start(__MODULE__, {username, password})
    account
  end

  def get_account_info(account) do
    GenServer.call(account, :get_account_info)
  end

  def get_portfolio(account) do
    GenServer.call(account, :get_portfolio)
  end

  # SERVER API

  @impl GenServer
  def init({username, password}) do
    send(self(), :login)
    {:ok, {username, password}}
  end

  @impl GenServer
  def handle_info(:login, {username, password}) do
    {:noreply, Api.login(username, password)}
  end

  @impl GenServer
  def handle_call(:get_account_info, _, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call(:get_portfolio, _, state) do
    {:reply, Api.get_portfolio(state), state}
  end
end
