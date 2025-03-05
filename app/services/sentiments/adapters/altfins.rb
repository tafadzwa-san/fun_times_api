# frozen_string_literal: true

require 'faraday'
require 'json'

module Services
  module Sentiments
    module Adapters
      class Altfins
        API_URL = 'https://api.altfins.com/v1/sentiment'
        API_KEY = ENV.fetch('ALTFINS_API_KEY', nil)

        def initialize(coin_symbol)
          @coin_symbol = coin_symbol
        end

        def fetch_sentiment
          response = request_sentiment
          raise Errors::AltfinsError, 'Failed to fetch sentiment from Altfins' unless response.success?

          parse_response(response.body)
        rescue Faraday::ConnectionFailed
          raise Errors::AltfinsError, 'Altfins API is unreachable'
        rescue JSON::ParserError
          raise Errors::AltfinsError, 'Invalid response from Altfins'
        rescue StandardError => e
          raise Errors::AltfinsError, "Unexpected error: #{e.message}"
        end

        private

        def request_sentiment
          Faraday.get(API_URL, { symbol: @coin_symbol, api_key: API_KEY })
        end

        def parse_response(body)
          data = JSON.parse(body)
          score = data['sentiment_score']
          raise Errors::AltfinsError, 'Sentiment score missing' unless score

          { source: 'Altfins', score: score }
        end
      end
    end
  end
end
