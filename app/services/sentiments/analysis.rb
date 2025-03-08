# frozen_string_literal: true

module Sentiments
  class Analysis
    ADAPTERS = [
      Sentiments::Adapters::LunarCrush,
      Sentiments::Adapters::Santiment,
      Sentiments::Adapters::Senticrypt
    ].freeze

    def initialize(coin_symbol)
      @coin_symbol = coin_symbol
    end

    def fetch_sentiment
      results = ADAPTERS.map { |adapter| fetch_from_adapter(adapter) }

      valid_results = results.reject { |result| result[:error] }
      errors = results.select { |result| result[:error] }.map { |e| e.slice(:source, :error) }

      {
        success: valid_results.any?,
        sentiment_scores: valid_results,
        errors: errors.presence || []
      }
    end

    private

    def fetch_from_adapter(adapter)
      adapter.new(@coin_symbol).fetch_sentiment
    rescue StandardError => e
      { source: adapter.name.demodulize, error: e.message }
    end
  end
end
