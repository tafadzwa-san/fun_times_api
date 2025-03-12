# typed: false
# frozen_string_literal: true

require 'base64'
require 'openssl'

module MarketData
  module Adapters
    class KuCoin < BaseAdapter
      API_URL = 'https://api.kucoin.com'

      def initialize(symbol, config = {})
        super
      end

      def fetch_market_data
        response = get('/api/v1/market/stats', { symbol: @symbol })

        # Check if the response contains an error code
        raise Errors::KuCoinError, response['msg'].to_s if response['code'] != '200000'

        data = response['data']

        # Check if market data is present
        raise Errors::KuCoinError, 'Market data missing' if data.blank? || !data['last']

        standardize_market_data(data)
      rescue StandardError => e
        raise Errors::KuCoinError, e.message
      end

      protected

      def extract_price(data)
        data['last'].to_f
      end

      def extract_volume(data)
        data['vol'].to_f
      end

      def extract_additional_data(data)
        {
          high_24h: data['high'].to_f,
          low_24h: data['low'].to_f,
          change_24h: (data['changeRate'].to_f * 100).round(2)
        }
      end

      def api_error_class
        Errors::KuCoinError
      end

      private

      def apply_authentication(request)
        timestamp = (Time.now.to_f * 1000).to_i.to_s

        # Build the string to sign
        path = request.path
        query = request.params.any? ? "?#{URI.encode_www_form(request.params)}" : ''

        string_to_sign = "#{timestamp}#{request.http_method.to_s.upcase}#{path}#{query}"

        # Generate the signature
        signature = Base64.strict_encode64(
          OpenSSL::HMAC.digest('sha256', @api_secret, string_to_sign)
        )

        # Add the headers
        request.headers['KC-API-KEY'] = @api_key
        request.headers['KC-API-SIGN'] = signature
        request.headers['KC-API-TIMESTAMP'] = timestamp
        request.headers['KC-API-PASSPHRASE'] = @api_passphrase
      end
    end
  end
end
