# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class Senticrypt
      API_URL = 'https://api.senticrypt.com/v1/sentiment'

      def initialize(coin_symbol)
        @coin_symbol = coin_symbol
      end

      def fetch_sentiment
        response = Faraday.get(API_URL, { symbol: @coin_symbol })

        return { error: 'SentiCrypt request failed' } unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        { error: 'SentiCrypt API unreachable' }
      rescue JSON::ParserError
        { error: 'Invalid JSON response from SentiCrypt' }
      rescue StandardError => e
        { error: "Unexpected error: #{e.message}" }
      end

      private

      def parse_response(body)
        data = JSON.parse(body)
        score = data['sentiment_score']
        return { error: 'Sentiment score missing from SentiCrypt response' } unless score

        { source: 'SentiCrypt', score: score }
      end
    end
  end
end
