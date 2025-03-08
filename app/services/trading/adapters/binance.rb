# frozen_string_literal: true

require 'faraday'
require 'json'

module Trading
  module Adapters
    class Binance
      API_URL = 'https://api.binance.com/api/v3'
      API_KEY = ENV.fetch('BINANCE_API_KEY', nil)
      API_SECRET = ENV.fetch('BINANCE_API_SECRET', nil)

      def initialize(symbol, action, quantity, price = nil)
        @symbol = symbol.upcase
        @action = action.upcase # "BUY" or "SELL"
        @quantity = quantity
        @price = price
      end

      def place_order
        response = request_order

        raise Errors::BinanceError, "Binance API Error: #{response.status}" unless response.success?

        parse_response(response.body)
      rescue Faraday::ConnectionFailed
        raise Errors::BinanceError, 'Binance API connection failed'
      rescue JSON::ParserError
        raise Errors::BinanceError, 'Invalid response format from Binance'
      rescue StandardError => e
        raise Errors::BinanceError, e.message
      end

      private

      def request_order
        params = build_order_params
        signed_params = sign_params(params)

        Faraday.post("#{API_URL}/order") do |req|
          req.headers['X-MBX-APIKEY'] = API_KEY
          req.headers['Content-Type'] = 'application/json'
          req.body = signed_params.to_json
        end
      end

      def build_order_params
        {
          symbol: @symbol,
          side: @action,
          type: @price.nil? ? 'MARKET' : 'LIMIT',
          quantity: @quantity,
          price: @price,
          timestamp: (Time.now.to_f * 1000).to_i
        }.compact
      end

      def sign_params(params)
        query_string = URI.encode_www_form(params)
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), API_SECRET, query_string)
        params.merge(signature: signature)
      end

      def parse_response(body)
        data = JSON.parse(body)
        {
          source: 'Binance',
          order_id: data['orderId'],
          executed_price: data['fills']&.first&.dig('price')&.to_f, # rubocop:disable Style/SafeNavigationChainLength
          quantity: data['executedQty'].to_f,
          status: data['status']
        }
      end
    end
  end
end
