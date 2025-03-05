# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :sentiment_query, resolver: Queries::SentimentQuery
  end
end
