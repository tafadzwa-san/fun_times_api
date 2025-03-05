# frozen_string_literal: true

module Services
  module Sentiments
    class Analysis
      ADAPTERS = [
        Services::Sentiments::Adapters::LunarCrush,
        Services::Sentiments::Adapters::Santiment,
        Services::Sentiments::Adapters::Altfins
      ].freeze

      def initialize(coin_symbol)
        @coin_symbol = coin_symbol
      end

      def fetch_sentiment
        results = ADAPTERS.map { |adapter| fetch_from_adapter(adapter) }

        valid_results = results.reject { |result| result[:error] }
        errors = results.select { |res| res[:error] }

        if valid_results.empty?
          return {
            success: false,
            sentiment_scores: [],
            error: errors.pluck(:error).join(', ').presence || 'No valid sentiment data available'
          }
        end

        {
          success: true,
          sentiment_scores: valid_results,
          errors: errors
        }
      end

      private

      def fetch_from_adapter(adapter)
        adapter.new(@coin_symbol).fetch_sentiment
      rescue Errors::LunarCrushError, Errors::SantimentError, Errors::AltfinsError => e
        { source: adapter.name.demodulize, error: e.message }
      rescue StandardError => e
        { source: adapter.name.demodulize, error: "Unexpected error: #{e.message}" }
      end
    end
  end
end
