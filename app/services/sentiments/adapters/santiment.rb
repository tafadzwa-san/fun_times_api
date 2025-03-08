# typed: false
# frozen_string_literal: true

require 'faraday'
require 'json'

module Sentiments
  module Adapters
    class Santiment
      API_URL = 'https://api.santiment.net/graphql'
      API_KEY = ENV.fetch('SANTIMENT_API_KEY', nil)

      def initialize(coin_symbol)
        @coin_symbol = coin_symbol
      end

      def fetch_sentiment
        response = request_sentiment
        raise Errors::SantimentError, 'Failed to fetch sentiment from Santiment' unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::SantimentError, 'Santiment API is unreachable'
      rescue JSON::ParserError
        raise Errors::SantimentError, 'Invalid response from Santiment'
      rescue StandardError => e
        raise Errors::SantimentError, "Unexpected error: #{e.message}"
      end

      private

      def request_sentiment
        Faraday.post(API_URL, query_payload.to_json, headers)
      end

      def parse_response(body)
        data = JSON.parse(body)
        score = data.dig('data', 'getSentimentData', 'score')
        raise Errors::SantimentError, 'Sentiment score missing' unless score

        { source: 'Santiment', score: score }
      end

      def query_payload
        {
          query: "{
              getSentimentData(asset: \"#{@coin_symbol}\") {
                score
              }
            }"
        }
      end

      def headers
        { 'Authorization' => "Bearer #{API_KEY}", 'Content-Type' => 'application/json' }
      end
    end
  end
end
