defmodule Degiro do
  use GenServer
  alias Degiro.Api

  # Degiro.login("username", "********") |> Degiro.get_account_info

  @moduledoc """
  Documentation for Degiro.
  """

  # CLIENT API

  @opaque account :: pid
  @opaque username :: String.t()
  @opaque password :: String.t()

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

  def get_cash_funds(account) do
    GenServer.call(account, :get_cash_funds)
  end

  def get_ask_bid_price(account, vwd_product_id \\ "591095107") do
    GenServer.call(account, {:get_ask_bid_price, vwd_product_id})
  end

  def search_product(account, search_query) do
    GenServer.call(account, {:search_product, search_query})
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

  @impl GenServer
  def handle_call(:get_cash_funds, _, state) do
    {:reply, Api.get_cash_funds(state), state}
  end

  @impl GenServer
  def handle_call({:get_ask_bid_price, vwd_product_id}, _, state) do
    {:reply, Api.get_ask_bid_price(state, vwd_product_id), state}
  end

  @impl GenServer
  def handle_call({:search_product, search_query}, _, state) do
    {:reply, Api.search_product(state, search_query), state}
  end
end
