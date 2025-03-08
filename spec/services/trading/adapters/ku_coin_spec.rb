# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trading::Adapters::KuCoin do
  subject(:adapter) { described_class.new('BTC-USDT', action, 0.5, price) }

  let(:action) { 'BUY' }
  let(:price) { nil } # Market order

  describe '#place_order' do
    context 'when the API request succeeds for market order' do
      before do
        stub_request(:post, %r{api.kucoin.com/api/v1/orders})
          .to_return(status: 200, body: {
            code: '200000',
            data: {
              orderId: '123456',
              dealSize: '0.5',
              dealFunds: '22500.00',
              status: 'FILLED'
            }
          }.to_json)
      end

      it 'returns the correct order details' do
        result = adapter.place_order

        expect(result).to eq(
          source: 'KuCoin',
          order_id: '123456',
          executed_price: 45_000.00, # dealFunds / dealSize
          quantity: 0.5,
          status: 'FILLED'
        )
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:post, %r{api.kucoin.com/api/v1/orders})
          .to_return(status: 500, body: '')
      end

      it 'raises a KuCoinError' do
        expect { adapter.place_order }.to raise_error(Errors::KuCoinError, 'KuCoin API Error: 500')
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:post, %r{api.kucoin.com/api/v1/orders})
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'raises a KuCoinError for connection failure' do
        expect { adapter.place_order }.to raise_error(Errors::KuCoinError, 'KuCoin API connection failed')
      end
    end

    context 'when response has invalid format' do
      before do
        stub_request(:post, %r{api.kucoin.com/api/v1/orders})
          .to_return(status: 200, body: 'invalid_json')
      end

      it 'raises a KuCoinError for invalid response' do
        expect do
          adapter.place_order
        end.to raise_error(Errors::KuCoinError, 'Invalid response format from KuCoin')
      end
    end
  end
end
