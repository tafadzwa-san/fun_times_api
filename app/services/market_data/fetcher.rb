# frozen_string_literal: true

require_relative 'adapters/binance'
require_relative 'adapters/ku_coin'
require_relative 'adapters/coin_gecko'

module Services
  module MarketData
    class Fetcher
      ADAPTERS = [
        Services::MarketData::Adapters::Binance,
        Services::MarketData::Adapters::KuCoin,
        Services::MarketData::Adapters::CoinGecko
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
end
