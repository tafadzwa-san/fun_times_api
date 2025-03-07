# frozen_string_literal: true

module Types
  class TradeExecutionMutationInput < Types::BaseInputObject
    argument :action, String, required: true
    argument :preferred_exchange, String, required: false
    argument :price, Float, required: false
    argument :quantity, Float, required: true
    argument :symbol, String, required: true
  end
end
