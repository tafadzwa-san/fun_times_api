# typed: false
# frozen_string_literal: true

module MarketData
  module Adapters
    class CoinGecko < BaseAdapter
      def fetch_market_data
        response = get('simple/price', { ids: @symbol, vs_currencies: 'usd' })

        raise Errors::CoinGeckoError, 'Market data missing' if response[@symbol].nil?

        standardize_market_data(response[@symbol])
      rescue StandardError => e
        raise Errors::CoinGeckoError, e.message
      end

      protected

      def extract_price(data)
        data['usd'].to_f
      end

      def extract_volume(_data)
        # CoinGecko does not provide volume in the simple price endpoint
        nil
      end

      def extract_additional_data(_data)
        {}
      end

      def api_error_class
        Errors::CoinGeckoError
      end

      private

      def apply_authentication(request)
        request.headers['X-Cg-Pro-Api-Key'] = @api_key
      end
    end
  end
end
