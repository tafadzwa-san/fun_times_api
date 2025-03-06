# frozen_string_literal: true

module Types
  class MarketDataResultType < Types::BaseObject
    field :errors, [Types::ErrorType], null: true
    field :market_data, [Types::MarketDataType], null: true
    field :success, Boolean, null: false
  end
end
