# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::CoinGecko do
  subject(:adapter) { described_class.new('bitcoin') }

  describe '#fetch_market_data' do
    context 'when the API request succeeds' do
      before do
        stub_request(:get, %r{api.coingecko.com/api/v3/simple/price})
          .to_return(status: 200, body: {
            bitcoin: {
              usd: 45_000.00,
              usd_market_cap: 900_000_000_000.00,
              usd_24h_vol: 30_000_000_000.00
            }
          }.to_json)
      end

      it 'returns the correct market data' do
        result = adapter.fetch_market_data

        expect(result).to eq(
          source: 'CoinGecko',
          symbol: 'BITCOIN',
          price: 45_000.00,
          market_cap: 900_000_000_000.00,
          volume: 30_000_000_000.00
        )
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, %r{api.coingecko.com/api/v3/simple/price})
          .to_return(status: 500, body: '')
      end

      it 'raises a CoinGeckoError' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::CoinGeckoError, 'CoinGecko API Error: 500')
      end
    end
  end
end
