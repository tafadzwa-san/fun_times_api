# typed: false
# frozen_string_literal: true

module MarketData
  module Adapters
    class BaseAdapter < ::Base::Adapter
      attr_reader :symbol

      def initialize(symbol, config)
        @symbol = format_symbol(symbol)
        super(config)
      end

      def fetch_market_data
        raise NotImplementedError, "#{self.class} must implement #fetch_market_data"
      end

      protected

      def format_symbol(symbol)
        symbol.to_s.upcase
      end

      def standardize_market_data(raw_data)
        {
          source: adapter_name,
          symbol: @symbol,
          price: extract_price(raw_data),
          volume: extract_volume(raw_data),
          timestamp: Time.now.utc,
          additional_data: extract_additional_data(raw_data)
        }
      end

      def extract_price(raw_data)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def extract_volume(raw_data)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def extract_additional_data(_raw_data)
        {} # Optional additional fields from specific adapters
      end

      def api_error_class
        Errors::MarketDataError
      end
    end
  end
end
