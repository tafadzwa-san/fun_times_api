# typed: false
# frozen_string_literal: true

module Types
  class SentimentScoreType < Types::BaseObject
    field :score, Float, null: false
    field :source, String, null: false
  end
end
