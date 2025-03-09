# typed: false
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :market_data_query, resolver: Queries::MarketDataQuery
    field :sentiment_query, resolver: Queries::SentimentQuery
  end
end
