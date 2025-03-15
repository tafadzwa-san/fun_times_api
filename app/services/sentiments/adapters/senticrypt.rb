# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class Senticrypt < BaseAdapter
      def fetch_sentiment
        response = get('/sentiment', { symbol: @symbol })

        raise Errors::SenticryptError, 'Sentiment data missing' if response['data'].blank?

        standardize_sentiment_data(response['data'].first)
      rescue StandardError => e
        raise Errors::SenticryptError, e.message
      end

      def fetch_buzzing_coins
        response = get('/trending', { limit: 20 })

        raise Errors::SenticryptError, 'Trending data missing' if response['data'].blank?

        response['data'].map do |coin_data|
          {
            symbol: coin_data['symbol'],
            score: extract_sentiment_score(coin_data)
          }
        end
      rescue StandardError => e
        raise Errors::SenticryptError, e.message
      end

      protected

      def extract_sentiment_score(data)
        data['sentiment_score'].to_f
      end

      def extract_additional_data(data)
        {
          sentiment_change: data['sentiment_change']
        }
      end

      def api_error_class
        Errors::SenticryptError
      end

      private

      def apply_authentication(request)
        request.headers['Authorization'] = "Bearer #{@api_key}"
      end
    end
  end
end
