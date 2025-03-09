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
        raise Errors::SenticryptError, 'Failed to fetch sentiment' unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::SenticryptError, 'API is unreachable'
      rescue JSON::ParserError
        raise Errors::SenticryptError, 'Invalid response'
      rescue StandardError => e
        raise Errors::SenticryptError, e.message
      end

      private

      def parse_response(body)
        data = JSON.parse(body)
        score = data['sentiment_score']
        raise Errors::SenticryptError, 'Score missing' unless score

        { source: 'SentiCrypt', score: score }
      end
    end
  end
end
