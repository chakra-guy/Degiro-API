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

  def get_orders(account) do
    GenServer.call(account, :get_orders)
  end

  def cancel_orders(account, orderId \\ "d1709040-96ea-4238-8c9d-5e3171a3478e") do
    GenServer.call(account, {:cancel_orders, orderId})
  end

  def place_orders(account, options \\ nil) do
    # FIXME add constants
    defaultOptions = %{
      # eMagin
      "productId" => "7270524",
      "buySell" => "BUY",
      "orderType" => 0,
      "timeType" => 3,
      "size" => 1,
      "price" => 0.3
    }

    case options do
      nil -> GenServer.call(account, {:place_orders, defaultOptions})
      _ -> GenServer.call(account, {:place_orders, options})
    end
  end

  def get_ask_bid_price(account, vwd_product_id \\ "591095107") do
    GenServer.call(account, {:get_ask_bid_price, vwd_product_id})
  end

  def get_product_by_id(account, product_ids \\ ["15018973", 8_066_561]) do
    GenServer.call(account, {:get_product_by_id, product_ids})
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
  def handle_call(:get_orders, _, state) do
    {:reply, Api.get_orders(state), state}
  end

  @impl GenServer
  def handle_call({:cancel_orders, orderId}, _, state) do
    {:reply, Api.cancel_orders(state, orderId), state}
  end

  @impl GenServer
  def handle_call({:place_orders, options}, _, state) do
    {:reply, Api.place_orders(state, options), state}
  end

  @impl GenServer
  def handle_call({:get_ask_bid_price, vwd_product_id}, _, state) do
    {:reply, Api.get_ask_bid_price(state, vwd_product_id), state}
  end

  @impl GenServer
  def handle_call({:get_product_by_id, product_ids}, _, state) do
    {:reply, Api.get_product_by_id(state, product_ids), state}
  end

  @impl GenServer
  def handle_call({:search_product, search_query}, _, state) do
    {:reply, Api.search_product(state, search_query), state}
  end
end
