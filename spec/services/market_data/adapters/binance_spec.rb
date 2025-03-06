# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::MarketData::Adapters::Binance do
  subject(:adapter) { described_class.new('BTCUSDT') }

  describe '#fetch_market_data' do
    context 'when the API request succeeds' do
      before do
        stub_request(:get, %r{api.binance.com/api/v3/ticker/24hr})
          .with(query: { symbol: 'BTCUSDT' })
          .to_return(status: 200, body: {
            lastPrice: '45000.00',
            volume: '123.45',
            quoteVolume: '5555555.55'
          }.to_json)
      end

      it 'returns the correct market data' do
        result = adapter.fetch_market_data

        expect(result).to eq(
          source: 'Binance',
          symbol: 'BTCUSDT',
          price: 45_000.0,
          volume: 123.45,
          quote_volume: 5_555_555.55
        )
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, %r{api.binance.com/api/v3/ticker/24hr})
          .with(query: { symbol: 'BTCUSDT' })
          .to_return(status: 500, body: '')
      end

      it 'raises a BinanceError' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError, 'Binance API Error: 500')
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, %r{api.binance.com/api/v3/ticker/24hr})
          .with(query: { symbol: 'BTCUSDT' })
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'raises a BinanceError for connection failure' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError, 'Binance API connection failed')
      end
    end

    context 'when response has invalid format' do
      before do
        stub_request(:get, %r{api.binance.com/api/v3/ticker/24hr})
          .with(query: { symbol: 'BTCUSDT' })
          .to_return(status: 200, body: 'invalid_json')
      end

      it 'raises a BinanceError for invalid response' do
        expect do
          adapter.fetch_market_data
        end.to raise_error(Errors::BinanceError, 'Invalid response format from Binance')
      end
    end
  end
end
