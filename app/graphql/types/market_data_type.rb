# typed: false
# frozen_string_literal: true

module Types
  class MarketDataType < Types::BaseObject
    field :market_cap, Float, null: true
    field :price, Float, null: false
    field :source, String, null: false
    field :symbol, String, null: false
    field :volume, Float, null: true
  end
end
