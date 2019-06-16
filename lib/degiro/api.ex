defmodule Degiro.Api do
  @base_url "https://trader.degiro.nl"
  @cookies_regex ~r/\Aset-cookie\z/i

  def login(username, password) do
    url = "#{@base_url}/login/secure/login"

    loginParams = %{
      "username" => username,
      "password" => password,
      "isRedirectToMobile" => false,
      "loginButtonUniversal" => "",
      "queryParams" => %{"reason" => "session_expired"}
    }

    # TODO add oneTimePassword stuff

    send_login_request(url, loginParams)
    |> update_config()
    |> get_client_info()
    |> get_session()
  end

  def get_portfolio(state) do
    get_data(state, %{"portfolio" => 0})
    |> get_in(["portfolio", "value"])
  end

  defp get_data(state, options \\ %{}) do
    %{
      "clientInfo" => %{"tradingUrl" => tradingUrl},
      "account" => account,
      "sessionId" => sessionId
    } = state

    params = URI.encode_query(options)
    url = "#{tradingUrl}v5/update/#{account};jsessionid=#{sessionId}?#{params}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()

      _ ->
        IO.puts("get_data error")
    end
  end

  defp send_login_request(url, loginParams) do
    body = Poison.encode!(loginParams)
    headers = [{"Content-type", "application/json"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} ->
        headers
        |> Enum.find(fn {key, _} -> String.match?(key, @cookies_regex) end)

      _ ->
        IO.puts("Login error")
    end
  end

  defp update_config(cookies) do
    [sessionId | _] = elem(cookies, 1) |> String.split(";")
    url = "#{@base_url}/login/secure/config"
    headers = [{"Cookie", "#{sessionId};"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()

      _ ->
        IO.puts("Login update config error")
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
