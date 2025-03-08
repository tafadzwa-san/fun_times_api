# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::KuCoin do
  subject(:adapter) { described_class.new('BTC-USDT') }

  describe '#fetch_market_data' do
    context 'when the API request succeeds' do
      before do
        stub_request(:get, %r{api.kucoin.com/api/v1/market/stats})
          .to_return(status: 200, body: {
            data: {
              last: '44800.00',
              vol: '50000.00',
              high: '45500.00',
              low: '44000.00'
            }
          }.to_json)
      end

      it 'returns the correct market data' do
        result = adapter.fetch_market_data

        expect(result).to eq(
          source: 'KuCoin',
          symbol: 'BTC-USDT',
          price: 44_800.00,
          volume: 50_000.00,
          high_24h: 45_500.00,
          low_24h: 44_000.00
        )
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, %r{api.kucoin.com/api/v1/market/stats})
          .to_return(status: 500, body: '')
      end

      it 'raises a KuCoinError' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::KuCoinError, 'KuCoin API Error: 500')
      end
    end
  end
end
