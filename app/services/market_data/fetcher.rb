# frozen_string_literal: true

module MarketData
  class Fetcher
    ADAPTERS = [
      MarketData::Adapters::Binance,
      MarketData::Adapters::KuCoin,
      MarketData::Adapters::CoinGecko
    ].freeze

    def initialize(coin_symbol)
      @coin_symbol = coin_symbol.upcase
    end

    def fetch_data
      results = ADAPTERS.map { |adapter| fetch_from_adapter(adapter) }

      valid_results = results.reject { |result| result[:error] }
      errors = results.select { |result| result[:error] }.map { |e| e.slice(:source, :error) }

      {
        success: valid_results.any?,
        market_data: valid_results,
        errors: errors.presence || []
      }
    end

    private

    def fetch_from_adapter(adapter)
      adapter.new(@coin_symbol).fetch_market_data
    rescue StandardError => e
      { source: adapter.name.demodulize, error: e.message }
    end
  end
end
