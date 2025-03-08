# typed: false
# frozen_string_literal: true

module Trading
  class ExecutionService
    SUPPORTED_EXCHANGES = [
      Trading::Adapters::Binance,
      Trading::Adapters::KuCoin
    ].freeze

    def initialize(symbol:, action:, quantity:, price: nil, preferred_exchange: nil)
      @symbol = symbol.upcase
      @action = action.downcase # "buy" or "sell"
      @quantity = quantity
      @price = price
      @preferred_exchange = preferred_exchange
    end

    def execute_trade
      selected_exchange = select_exchange

      return failure_response('No available exchange to execute trade') if selected_exchange.nil?

      trade = selected_exchange.new(
        @symbol, @action, @quantity, @price
      ).place_order

      success_response(trade)
    rescue StandardError => e
      failure_response("Trade execution failed: #{e.message}")
    end

    private

    def select_exchange
      return find_exchange(@preferred_exchange) if @preferred_exchange

      # Automatically select the best exchange based on availability & liquidity
      SUPPORTED_EXCHANGES.find { |exchange| exchange_available?(exchange) }
    end

    def find_exchange(name)
      SUPPORTED_EXCHANGES.find { |exchange| exchange.name.demodulize == name }
    end

    def exchange_available?(_exchange)
      # Here we could add logic to check liquidity, trading fees, or API availability
      true
    end

    def success_response(data)
      { success: true, trade: data, error: nil }
    end

    def failure_response(message)
      { success: false, trade: nil, error: message }
    end
  end
end
