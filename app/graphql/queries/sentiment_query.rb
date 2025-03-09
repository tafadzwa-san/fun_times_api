# typed: false
# frozen_string_literal: true

module Queries
  class SentimentQuery < Queries::BaseQuery
    type Types::SentimentResultType, null: false
    argument :coin_symbol, String, required: true

    def resolve(coin_symbol:)
      result = Sentiments::Analysis.new(coin_symbol).fetch_sentiment

      {
        success: result[:success],
        sentiment_scores: result[:sentiment_scores],
        errors: result[:errors] || []
      }
    rescue StandardError => e
      {
        success: false,
        sentiment_scores: [],
        errors: [{ source: 'SentimentQuery', error: e.message }]
      }
    end
  end
end
