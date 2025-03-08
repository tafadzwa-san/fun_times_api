# typed: false
# frozen_string_literal: true

require 'faraday'
require 'json'
require 'base64'
require 'openssl'

module Trading
  module Adapters
    class KuCoin
      API_URL = 'https://api.kucoin.com/api/v1'
      API_KEY = ENV.fetch('KUCOIN_API_KEY', nil)
      API_SECRET = ENV.fetch('KUCOIN_API_SECRET', nil)
      API_PASSPHRASE = ENV.fetch('KUCOIN_API_PASSPHRASE', nil)

      def initialize(symbol, action, quantity, price = nil)
        @symbol = symbol.upcase
        @action = action.upcase # "BUY" or "SELL"
        @quantity = quantity
        @price = price
      end

      def place_order
        response = request_order

        raise Errors::KuCoinError, "KuCoin API Error: #{response.status}" unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::KuCoinError, 'KuCoin API connection failed'
      rescue JSON::ParserError
        raise Errors::KuCoinError, 'Invalid response format from KuCoin'
      rescue StandardError => e
        raise Errors::KuCoinError, e.message
      end

      private

      def request_order
        params = build_order_params
        headers = sign_headers(params)

        Faraday.post("#{API_URL}/orders") do |req|
          req.headers.merge!(headers)
          req.headers['Content-Type'] = 'application/json'
          req.body = params.to_json
        end
      end

      def build_order_params
        {
          clientOid: SecureRandom.uuid,
          side: @action.downcase,
          symbol: @symbol,
          type: @price.nil? ? 'market' : 'limit',
          price: @price,
          size: @quantity
        }.compact
      end

      def sign_headers(params)
        timestamp = (Time.now.to_f * 1000).to_i.to_s
        payload = "#{timestamp}POST/api/v1/orders#{params.to_json}"
        signature = Base64.strict_encode64(
          OpenSSL::HMAC.digest('sha256', API_SECRET, payload)
        )
        passphrase = Base64.strict_encode64(
          OpenSSL::HMAC.digest('sha256', API_SECRET, API_PASSPHRASE)
        )

        {
          'KC-API-KEY': API_KEY,
          'KC-API-SIGN': signature,
          'KC-API-TIMESTAMP': timestamp,
          'KC-API-PASSPHRASE': passphrase,
          'KC-API-KEY-VERSION': '2'
        }
      end

      def parse_response(body)
        data = JSON.parse(body)
        order = data['data']

        {
          source: 'KuCoin',
          order_id: order['orderId'],
          executed_price: order['dealFunds'].to_f / order['dealSize'].to_f, # rubocop:disable Style/FloatDivision
          quantity: order['dealSize'].to_f,
          status: order['status']
        }
      end
    end
  end
end
