# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Fetcher do
  subject(:fetcher) { described_class.new('BTC') }

  before do
    allow(MarketData::Adapters::Binance).to receive(:new)
      .with('BTC').and_return(instance_double(
                                MarketData::Adapters::Binance,
                                fetch_market_data: { source: 'Binance', symbol: 'BTC', price: 45_000.00,
                                                     volume: 100_000.00 }
                              ))

    allow(MarketData::Adapters::KuCoin).to receive(:new)
      .with('BTC').and_return(instance_double(
                                MarketData::Adapters::KuCoin,
                                fetch_market_data: { source: 'KuCoin', symbol: 'BTC', price: 44_800.00,
                                                     volume: 50_000.00 }
                              ))

    allow(MarketData::Adapters::CoinGecko).to receive(:new)
      .with('BTC').and_return(instance_double(
                                MarketData::Adapters::CoinGecko,
                                fetch_market_data: { source: 'CoinGecko', symbol: 'BTC', price: 44_500.00,
                                                     volume: 25_000_000.00 }
                              ))
  end

  describe '#fetch_data' do
    it 'aggregates market data from multiple sources' do
      result = fetcher.fetch_data

      expect(result[:success]).to be true
      expect(result[:market_data]).to contain_exactly(
        { source: 'Binance', symbol: 'BTC', price: 45_000.00, volume: 100_000.00 },
        { source: 'KuCoin', symbol: 'BTC', price: 44_800.00, volume: 50_000.00 },
        { source: 'CoinGecko', symbol: 'BTC', price: 44_500.00, volume: 25_000_000.00 }
      )
    end

    context 'when one adapter fails' do
      before do
        allow(MarketData::Adapters::KuCoin).to receive(:new)
          .and_raise(Errors::KuCoinError, 'KuCoin API Error')
      end

      it 'continues processing with other sources' do
        result = fetcher.fetch_data

        expect(result[:success]).to be true
        expect(result[:market_data]).to include(
          { source: 'Binance', symbol: 'BTC', price: 45_000.00, volume: 100_000.00 },
          { source: 'CoinGecko', symbol: 'BTC', price: 44_500.00, volume: 25_000_000.00 }
        )
        expect(result[:market_data]).not_to include(hash_including(source: 'KuCoin'))
        expect(result[:errors]).to include({ source: 'KuCoin', error: 'KuCoin API Error' })
      end
    end
  end
end
