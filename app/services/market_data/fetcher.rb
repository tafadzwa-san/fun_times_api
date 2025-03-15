# typed: false
# frozen_string_literal: true

module MarketData
  class Fetcher
    include BaseService

    use_adapters Adapters::Binance, Adapters::KuCoin, Adapters::CoinGecko
    configure ServicesConfig.market_data_config

    def call
      with_caching('market_data') do
        fetch_market_data
      end
    end

    private

    def fetch_market_data
      fetch_data_with_adapters(:fetch_market_data)
    end
  end
end
