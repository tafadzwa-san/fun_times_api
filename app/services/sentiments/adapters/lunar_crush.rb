# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class LunarCrush < BaseAdapter
      def fetch_sentiment
        response = get('/assets', { symbol: @symbol })

        raise Errors::LunarCrushError, 'Sentiment data missing' if response['data'].blank?

        standardize_sentiment_data(response['data'].first)
      rescue StandardError => e
        raise Errors::LunarCrushError, e.message
      end

      def fetch_buzzing_coins
        response = get('/assets', { limit: 20, sort: 'galaxy_score' })

        raise Errors::LunarCrushError, 'Sentiment data missing' if response['data'].blank?

        response['data'].map do |coin_data|
          {
            symbol: coin_data['symbol'],
            score: extract_sentiment_score(coin_data)
          }
        end
      rescue StandardError => e
        raise Errors::LunarCrushError, e.message
      end

      protected

      def extract_sentiment_score(data)
        data['galaxy_score'].to_f
      end

      def extract_additional_data(data)
        {
          alt_rank: data['alt_rank'],
          volatility: data['volatility']
        }
      end

      def api_error_class
        Errors::LunarCrushError
      end

      private

      def apply_authentication(request)
        request.params['key'] = @api_key
      end
    end
  end
end
