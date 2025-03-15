# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class BaseAdapter < ::Base::Adapter
      attr_reader :symbol

      def initialize(symbol, config = {})
        @symbol = format_symbol(symbol)
        super(config)
      end

      def fetch_sentiment
        raise NotImplementedError, "#{self.class} must implement #fetch_sentiment"
      end

      def fetch_buzzing_coins
        raise NotImplementedError, "#{self.class} must implement #fetch_buzzing_coins"
      end

      protected

      def format_symbol(symbol)
        symbol.to_s.upcase
      end

      def standardize_sentiment_data(raw_data)
        {
          source: adapter_name,
          symbol: @symbol,
          score: extract_sentiment_score(raw_data),
          timestamp: Time.now.utc,
          additional_data: extract_additional_data(raw_data)
        }
      end

      def extract_sentiment_score(raw_data)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def extract_additional_data(_raw_data)
        {} # Optional additional fields from specific adapters
      end

      def api_error_class
        Errors::SentimentError
      end
    end
  end
end
