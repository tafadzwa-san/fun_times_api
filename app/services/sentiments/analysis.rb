# frozen_string_literal: true

module Services
  module Sentiments
    class Analysis
      ADAPTERS = [
        Services::Sentiments::Adapters::LunarCrush,
        Services::Sentiments::Adapters::Santiment,
        Services::Sentiments::Adapters::Senticrypt
      ].freeze

      def initialize(coin_symbol)
        @coin_symbol = coin_symbol
      end

      def fetch_sentiment
        results = ADAPTERS.map { |adapter| fetch_from_adapter(adapter) }

        valid_results = results.reject { |result| result[:error] }

        if valid_results.empty?
          return {
            success: false,
            sentiment_scores: [],
            error: results.pluck(:error).compact.uniq.join(', ')
          }
        end

        {
          success: true,
          sentiment_scores: valid_results,
          errors: results.select { |res| res[:error] }
        }
      end

      private

      def fetch_from_adapter(adapter)
        adapter.new(@coin_symbol).fetch_sentiment
      rescue StandardError => e
        { source: adapter.name.demodulize, error: "Error fetching sentiment: #{e.message}" }
      end
    end
  end
end
