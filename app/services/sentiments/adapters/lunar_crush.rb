# typed: false
# frozen_string_literal: true

require 'faraday'
require 'json'

module Sentiments
  module Adapters
    class LunarCrush
      API_URL = 'https://api.lunarcrush.com/v2'
      API_KEY = ENV.fetch('LUNARCRUSH_API_KEY', nil)

      def initialize(coin_symbol)
        @coin_symbol = coin_symbol
      end

      def fetch_sentiment
        response = request_sentiment
        raise Errors::LunarCrushError, 'Failed to fetch sentiment' unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::LunarCrushError, 'API is unreachable'
      rescue JSON::ParserError
        raise Errors::LunarCrushError, 'Invalid response'
      rescue StandardError => e
        raise Errors::LunarCrushError, e.message
      end

      private

      def request_sentiment
        Faraday.get("#{API_URL}/assets", { data: 'metrics', key: API_KEY, symbol: @coin_symbol })
      end

      def parse_response(body)
        data = JSON.parse(body)
        score = data.dig('data', 0, 'galaxy_score')
        raise Errors::LunarCrushError, 'Score missing' unless score

        { source: 'LunarCrush', score: score }
      end
    end
  end
end
