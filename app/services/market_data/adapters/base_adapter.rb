# typed: false
# frozen_string_literal: true

module MarketData
  module Adapters
    class BaseAdapter < ::Base::Adapter
      attr_reader :symbol, :api_key, :api_secret

      def initialize(symbol, config = {})
        @symbol = symbol.upcase
        @api_key = service_config[:api_key]
        @api_secret = service_config[:api_secret]
        super(config)
      end

      def fetch_market_data
        raise NotImplementedError, "#{self.class} must implement #fetch_market_data"
      end

      protected

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

      # Methods to be implemented by subclasses
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

      private

      def service_config
        @service_config ||= {
          api_key: ENV.fetch("#{adapter_name.upcase}_API_KEY", nil),
          api_secret: ENV.fetch("#{adapter_name.upcase}_API_SECRET", nil)
        }
      end
    end
  end
end
