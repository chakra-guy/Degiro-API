defmodule Degiro.Api do
  @degiro_url "https://trader.degiro.nl"
  @degiro_vwd_services_url "https://degiro.quotecast.vwdservices.com/CORS/"
  @cookies_regex ~r/\Aset-cookie\z/i
  @product_types %{
    all: nil,
    shares: 1,
    bonds: 2,
    futures: 7,
    options: 8,
    investmendFunds: 13,
    leveragedProducts: 14,
    etfs: 131,
    cfds: 535,
    warrants: 536
  }

  def login(username, password) do
    url = "#{@degiro_url}/login/secure/login"

    loginParams = %{
      "username" => username,
      "password" => password,
      "isRedirectToMobile" => false,
      "loginButtonUniversal" => "",
      "queryParams" => %{"reason" => "session_expired"}
    }

    # TODO add oneTimePassword stuff
    # FIXME use the "with" keyword for the login chains

    send_login_request(url, loginParams)
    |> update_config()
    |> get_client_info()
    |> get_session()
  end

  def get_portfolio(state) do
    get_data(state, %{"portfolio" => 0}) |> get_in(["portfolio", "value"])
  end

  def get_cash_funds(state) do
    get_data(state, %{"cashFunds" => 0}) |> get_in(["cashFunds", "value"])
  end

  defp get_data(state, options) do
    %{
      "clientInfo" => %{"tradingUrl" => tradingUrl},
      "account" => account,
      "sessionId" => sessionId
    } = state

    params = URI.encode_query(options)
    url = "#{tradingUrl}v5/update/#{account};jsessionid=#{sessionId}?#{params}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} -> Poison.decode!(body)
      _ -> IO.puts("get_data error")
    end
  end

  def get_ask_bid_price(%{"userToken" => userToken}, vwd_product_id) do
    %{"sessionId" => vwdSessionId} = get_vwd_session(userToken)

    controlData =
      [
        "req(#{vwd_product_id}.BidPrice);",
        "req(#{vwd_product_id}.AskPrice);",
        "req(#{vwd_product_id}.LastPrice);",
        "req(#{vwd_product_id}.LastTime);"
      ]
      |> Enum.join()

    url = "#{@degiro_vwd_services_url}#{vwdSessionId}"
    body = Poison.encode!(%{"controlData" => controlData})
    headers = [{"Origin", @degiro_url}]

    with {:ok, %HTTPoison.Response{status_code: 200}} <- HTTPoison.post(url, body, headers),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(url) do
      {:ok, Poison.decode!(body)}
    else
      {:error, %HTTPoison.Error{reason: reason}} -> IO.puts(reason)
      _ -> IO.puts("get_ask_bid_price error")
    end
  end

  defp get_vwd_session(userToken) do
    url = "#{@degiro_vwd_services_url}request_session?version=1.0.20170315&userToken=#{userToken}"
    body = Poison.encode!(%{"referrer" => @degiro_url})
    headers = [{"Origin", @degiro_url}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode!(body)
      _ -> IO.puts("get_vwd_session error")
    end
  end

  def get_product_by_id(state, product_ids) do
    %{
      "clientInfo" => %{"productSearchUrl" => productSearchUrl},
      "account" => account,
      "sessionId" => sessionId
    } = state

    url = "#{productSearchUrl}v5/products/info?intAccount=#{account}&sessionId=#{sessionId}"
    body = product_ids |> Enum.map(&to_string/1) |> Poison.encode!()
    headers = [{"Content-type", "application/json"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode!(body)
      _ -> IO.puts("get_vwd_session error")
    end
  end

  def search_product(state, search_query) do
    %{
      "clientInfo" => %{"productSearchUrl" => productSearchUrl},
      "account" => account,
      "sessionId" => sessionId
    } = state

    params =
      [
        {"intAccount", account},
        {"sessionId", sessionId},
        {"searchText", search_query},
        {"productTypeId", @product_types.all},
        {"sortColumns", nil},
        {"sortTypes", nil},
        {"limit", 7},
        {"offset", 0}
      ]
      |> Enum.filter(fn {_, v} -> v != nil end)
      |> Enum.into(%{})
      |> URI.encode_query()

    url = "#{productSearchUrl}v5/products/lookup?#{params}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode!(body)
      _ -> IO.puts("search_product error")
    end
  end

  defp send_login_request(url, loginParams) do
    body = Poison.encode!(loginParams)
    headers = [{"Content-type", "application/json"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} ->
        headers |> Enum.find(fn {key, _} -> String.match?(key, @cookies_regex) end)

      _ ->
        IO.puts("Login error")
    end
  end

  defp update_config(cookies) do
    [sessionId | _] = elem(cookies, 1) |> String.split(";")
    url = "#{@degiro_url}/login/secure/config"
    headers = [{"Cookie", "#{sessionId};"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> Poison.decode!(body)
      _ -> IO.puts("Login update config error")
    end
  end

  defp get_client_info(%{"paUrl" => paUrl, "sessionId" => sessionId} = urls) do
    url = "#{paUrl}client?sessionId=#{sessionId}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()
        |> Map.get("data")
        |> Map.merge(urls)

      _ ->
        IO.puts("Login get client info error")
    end
  end

  defp get_session(%{"sessionId" => sessionId, "id" => id, "intAccount" => intAccount} = data) do
    %{
      "sessionId" => sessionId,
      "account" => intAccount,
      "userToken" => id,
      "clientInfo" => data
    }
  end
end
