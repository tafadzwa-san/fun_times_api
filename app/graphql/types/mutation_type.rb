# typed: false
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :trade_execution, mutation: Mutations::TradeExecutionMutation
  end
end
