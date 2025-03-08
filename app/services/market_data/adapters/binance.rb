# frozen_string_literal: true

require 'faraday'

module MarketData
  module Adapters
    class Binance
      API_URL = 'https://api.binance.com/api/v3'

      def initialize(symbol)
        @symbol = symbol.upcase
      end

      def fetch_market_data
        response = request_market_data

        raise Errors::BinanceError, "Binance API Error: #{response.status}" unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::BinanceError, 'Binance API connection failed'
      rescue JSON::ParserError
        raise Errors::BinanceError, 'Invalid response format from Binance'
      rescue StandardError => e
        raise Errors::BinanceError, e.message
      end

      private

      def request_market_data
        Faraday.get("#{API_URL}/ticker/24hr", { symbol: @symbol })
      end

      def parse_response(body)
        data = JSON.parse(body)

        {
          source: 'Binance',
          symbol: @symbol,
          price: data['lastPrice'].to_f,
          volume: data['volume'].to_f,
          quote_volume: data['quoteVolume'].to_f
        }
      end
    end
  end
end
