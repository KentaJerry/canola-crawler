defmodule SimpleCrawler do
  def get_url(url) do
    case HTTPoison.get!(url) do
      %{status_code: 200} = responce ->
        {:ok, document} = Floki.parse_document(responce.body)
        document |> Floki.find("a") |> Floki.attribute("href")

      _ -> []
    end
  end
  def get_urls(url_list) do
    domain = "/tokyo/city_131202"

    list =
      Enum.map(url_list, fn url ->
        url
        |> get_url()
        |> Enum.filter(& String.starts_with?(&1, domain))
      end )

      List.flatten(list)
  end

  def check_url(url_list) do
    url_list = Enum.map(url_list, & format_url/1)

    all_url = Enum.uniq(url_list ++ get_urls(url_list))

    if all_url == url_list || length(all_url) > 10 do
      all_url
    else
      check_url(all_url)
    end
  end

  def get_info(url) do
    flagment = Floki.parse_fragment!(HTTPoison.get!(url).body)

    %{
      "campanye" => get_flagment_text(flagment, "h1"),
      "address" => get_flagment_text(flagment, ".p-companies-show-profile__info-address")
    }
  end

  defp get_flagment_text(flagment, selector) do
    text = Floki.text(Floki.find(flagment, selector))
    String.replace(text,["\n"," "], "")
  end

  defp format_url("https://tsukulink.net/" <> _uri = url), do: url

  defp format_url(url), do: "https://tsukulink.net" <> url


  @base_url "https://tsukulink.net/tokyo/city_131202?psafe_param=1&utm_source=google&utm_medium=cpc&utm_campaign=03&gclid=Cj0KCQjwho-lBhC_ARIsAMpgMoe7Tz8KHRWMx4o-BPaipmjzYzbP6-buGT8EXUtUmKrvj88tFRaGecoaAjvmEALw_wcB"
  def run() do
    [@base_url]
    |> check_url()
    |> Enum.map(& format_url/1)
    |> Enum.map(& get_info/1)
    # |> Enum.filter(fn %{"address" => address} -> String.contains?(address, "石神井") end)
  end



end
