# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class Santiment < BaseAdapter
      def fetch_sentiment
        query = build_sentiment_query

        response = post('', { query: query })
        data = response.dig('data', 'getMetric', 'timeseriesData')

        raise Errors::SantimentError, 'Sentiment data missing' if data.blank?

        standardize_sentiment_data(data.last)
      rescue StandardError => e
        raise Errors::SantimentError, e.message
      end

      def fetch_buzzing_coins
        query = build_trending_coins_query

        response = post('', { query: query })
        data = response.dig('data', 'getTrendingWords', 'topWords')

        raise Errors::SantimentError, 'Trending coins data missing' if data.blank?

        data.filter_map do |word_data|
          next unless word_data['word']

          {
            symbol: word_data['word'].upcase,
            score: 100 - (word_data['rank'].to_f * 5) # Convert rank 1-20 to score 95-0
          }
        end
      rescue StandardError => e
        raise Errors::SantimentError, e.message
      end

      protected

      def extract_sentiment_score(data)
        value = data['value']
        # Normalize to a 0-100 scale
        value.to_f * 100 if value
      end

      def extract_additional_data(data)
        {
          timestamp: data['datetime'],
          metric: 'sentiment_balance'
        }
      end

      def api_error_class
        Errors::SantimentError
      end

      private

      def build_sentiment_query
        <<~GRAPHQL
          {
            getMetric(metric: "sentiment_balance") {
              timeseriesData(
                slug: "#{@symbol.downcase}"
                from: "#{7.days.ago.iso8601}"
                to: "#{Time.now.iso8601}"
                interval: "1d"
              ) {
                datetime
                value
              }
            }
          }
        GRAPHQL
      end

      def build_trending_coins_query
        <<~GRAPHQL
          {
            getTrendingWords(
              from: "#{1.day.ago.iso8601}"
              to: "#{Time.now.iso8601}"
            ) {
              topWords {
                word
                rank
                score
              }
            }
          }
        GRAPHQL
      end

      def apply_authentication(request)
        request.headers['Authorization'] = "Bearer #{@api_key}"
      end
    end
  end
end
