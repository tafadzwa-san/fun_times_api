# frozen_string_literal: true

module Types
  class TradeDetailsType < Types::BaseObject
    field :executed_price, Float, null: true
    field :order_id, String, null: false
    field :quantity, Float, null: false
    field :source, String, null: false
    field :status, String, null: false
  end
end
