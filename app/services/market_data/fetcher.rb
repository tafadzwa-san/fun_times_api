# typed: false
# frozen_string_literal: true

require 'solid_cache'

module MarketData
  class Fetcher
    ADAPTERS = [
      MarketData::Adapters::Binance,
      MarketData::Adapters::KuCoin,
      MarketData::Adapters::CoinGecko
    ].freeze

    CACHE_EXPIRY = ENV.fetch('MARKET_DATA_CACHE_TTL', 15).to_i

    def initialize(coin_symbol, force_refresh: false)
      @coin_symbol = coin_symbol.upcase
      @force_refresh = force_refresh
      @cache = SolidCache::Store.new
    end

    def fetch_data
      cache_key = "market_data:#{@coin_symbol}"

      cached_data = @cache.read(cache_key.to_s)
      return cached_data if cached_data && !@force_refresh

      data = fetch_market_data
      cache_market_data(cache_key, data) if data[:success]
      data
    end

    private

    def fetch_from_adapter(adapter)
      adapter.new(@coin_symbol).fetch_market_data
    rescue StandardError => e
      { source: adapter.name.demodulize, error: e.message }
    end

    def fetch_market_data
      results = ADAPTERS.map { |adapter| fetch_from_adapter(adapter) }
      valid_results = results.reject { |result| result[:error] }
      errors = results.select { |result| result[:error] }.map { |e| e.slice(:source, :error) }

      {
        success: valid_results.any?,
        market_data: valid_results,
        errors: errors.presence || []
      }
    end

    def cache_market_data(cache_key, data)
      @cache.write(cache_key, data, expires_in: CACHE_EXPIRY)
    end
  end
end
