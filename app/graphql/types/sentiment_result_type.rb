# frozen_string_literal: true

module Types
  class SentimentResultType < Types::BaseObject
    field :error, String, null: true
    field :sentiment_scores, [Types::SentimentScoreType], null: true
    field :success, Boolean, null: false
  end
end
