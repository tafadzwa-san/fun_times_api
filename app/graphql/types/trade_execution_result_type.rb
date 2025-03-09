# typed: false
# frozen_string_literal: true

module Types
  class TradeExecutionResultType < Types::BaseObject
    field :errors, [Types::ErrorType], null: true
    field :success, Boolean, null: false
    field :trade, Types::TradeDetailsType, null: true
  end
end
