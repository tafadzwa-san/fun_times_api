# typed: false
# frozen_string_literal: true

module MarketData
  module Adapters
    class Binance < BaseAdapter
      def fetch_market_data
        response = get('/api/v3/ticker/price', { symbol: @symbol })

        raise Errors::BinanceError, 'Market data missing' if response['price'].nil?

        standardize_market_data(response)
      rescue StandardError => e
        raise Errors::BinanceError, e.message
      end

      protected

      def extract_price(data)
        data['price'].to_f
      end

      def extract_volume(_data)
        # Binance does not provide volume in the ticker price endpoint
        nil
      end

      def extract_additional_data(_data)
        {}
      end

      def api_error_class
        Errors::BinanceError
      end

      def apply_authentication(request)
        request.params[:timestamp] = (Time.now.to_f * 1000).to_i
        query_string = URI.encode_www_form(request.params)
        signature = OpenSSL::HMAC.hexdigest('sha256', @api_secret, query_string)
        request.params[:signature] = signature
        request.headers['X-MBX-APIKEY'] = @api_key
      end
    end
  end
end
