# typed: false
# frozen_string_literal: true

require 'faraday'
require 'json'

module MarketData
  module Adapters
    class CoinGecko
      API_URL = 'https://api.coingecko.com/api/v3'

      def initialize(symbol)
        @symbol = symbol.downcase
      end

      def fetch_market_data
        response = request_market_data

        raise Errors::CoinGeckoError, "CoinGecko API Error: #{response.status}" unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::CoinGeckoError, 'CoinGecko API connection failed'
      rescue JSON::ParserError
        raise Errors::CoinGeckoError, 'Invalid response format from CoinGecko'
      rescue StandardError => e
        raise Errors::CoinGeckoError, e.message
      end

      private

      def request_market_data
        Faraday.get("#{API_URL}/simple/price",
                    { ids: @symbol, vs_currencies: 'usd', include_market_cap: 'true', include_24hr_vol: 'true' })
      end

      def parse_response(body)
        data = JSON.parse(body)[@symbol]
        return { error: 'Market data missing from CoinGecko' } unless data

        {
          source: 'CoinGecko',
          symbol: @symbol.upcase,
          price: data['usd'].to_f,
          market_cap: data['usd_market_cap'].to_f,
          volume: data['usd_24h_vol'].to_f
        }
      end
    end
  end
end
