# typed: false
# frozen_string_literal: true

module Mutations
  class TradeExecutionMutation < Mutations::BaseMutation
    argument :input, Types::TradeExecutionInputType, required: true
    type Types::TradeExecutionResultType, null: false

    def resolve(input:) # rubocop:disable Metrics/MethodLength
      service = Services::Trading::ExecutionService.new(
        symbol: input[:symbol],
        action: input[:action],
        quantity: input[:quantity],
        price: input[:price],
        preferred_exchange: input[:preferred_exchange]
      )

      result = service.execute_trade

      {
        success: result[:success],
        trade: result[:trade],
        errors: result[:errors] || []
      }
    rescue StandardError => e
      {
        success: false,
        trade: nil,
        errors: [{ source: 'TradeExecutionMutation', error: e.message }]
      }
    end
  end
end
