# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trading::Adapters::Binance do
  subject(:adapter) { described_class.new('BTCUSDT', action, 0.5, price) }

  let(:action) { 'BUY' }
  let(:price) { nil } # Market order

  describe '#place_order' do
    context 'when the API request succeeds for market order' do
      before do
        stub_request(:post, %r{api.binance.com/api/v3/order})
          .to_return(status: 200, body: {
            orderId: 123_456,
            executedQty: '0.5',
            status: 'FILLED',
            fills: [{ price: '45000.00' }]
          }.to_json)
      end

      it 'returns the correct order details' do
        result = adapter.place_order

        expect(result).to eq(
          source: 'Binance',
          order_id: 123_456,
          executed_price: 45_000.00,
          quantity: 0.5,
          status: 'FILLED'
        )
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:post, %r{api.binance.com/api/v3/order})
          .to_return(status: 500, body: '')
      end

      it 'raises a BinanceError' do
        expect { adapter.place_order }.to raise_error(Errors::BinanceError, 'Binance API Error: 500')
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:post, %r{api.binance.com/api/v3/order})
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'raises a BinanceError for connection failure' do
        expect { adapter.place_order }.to raise_error(Errors::BinanceError, 'Binance API connection failed')
      end
    end

    context 'when response has invalid format' do
      before do
        stub_request(:post, %r{api.binance.com/api/v3/order})
          .to_return(status: 200, body: 'invalid_json')
      end

      it 'raises a BinanceError for invalid response' do
        expect do
          adapter.place_order
        end.to raise_error(Errors::BinanceError, 'Invalid response format from Binance')
      end
    end
  end
end
