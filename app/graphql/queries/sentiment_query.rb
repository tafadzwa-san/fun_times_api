# frozen_string_literal: true

module Queries
  class SentimentQuery < Queries::BaseQuery
    type Types::SentimentResultType, null: false

    argument :coin_symbol, String, required: true

    def resolve(coin_symbol:)
      Services::Sentiments::Analysis.new(coin_symbol).fetch_sentiment
    rescue StandardError => e
      GraphQL::ExecutionError.new("Error fetching sentiment data: #{e.message}")
    end
  end
end
