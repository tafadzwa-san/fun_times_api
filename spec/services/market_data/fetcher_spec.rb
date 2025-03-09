# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Fetcher, type: :service do # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:fetcher) { described_class.new(coin_symbol, force_refresh: force_refresh) }

  let(:coin_symbol) { 'BTC' }
  let(:force_refresh) { false }
  let(:cache_store) { SolidCache::Store.new }
  let(:cache_key) { "market_data:#{coin_symbol.upcase}" }
  let(:mock_market_data) { { source: 'Binance', price: 45_000 } }
  let(:mock_error) { { source: 'Binance', error: 'Timeout error' } }

  before do
    cache_store.clear # Ensure clean cache

    # Stub external API calls
    stub_request(:get, 'https://api.kucoin.com/api/v1/market/stats?symbol=BTC')
      .to_return(
        status: 200,
        body: { price: '46000' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT')
      .to_return(
        status: 200,
        body: { price: '45000' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price')
      .with(
        query: {
          ids: 'btc',
          vs_currencies: 'usd',
          include_market_cap: 'true',
          include_24hr_vol: 'true'
        }
      )
      .to_return(
        status: 200,
        body: { btc: { usd: 44_000, market_cap: 100_000_000, '24h_vol' => 1_000_000 } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    allow(SolidCache::Store).to receive(:new).and_return(cache_store)
  end

  describe '#fetch_data' do # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'when API responses are successful' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:binance_adapter) { instance_double(MarketData::Adapters::Binance, fetch_market_data: mock_market_data) }
      let(:kucoin_adapter) { instance_double(MarketData::Adapters::KuCoin, fetch_market_data: mock_market_data) }
      let(:coingecko_adapter) { instance_double(MarketData::Adapters::CoinGecko, fetch_market_data: mock_market_data) }

      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_adapter)
        allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_adapter)
        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coingecko_adapter)
      end

      it 'returns aggregated market data' do
        result = fetcher.fetch_data
        expect(result[:success]).to be true
        expect(result[:market_data].size).to eq(3)
      end

      it 'caches the successful response' do
        result = fetcher.fetch_data

        expect(result[:success]).to be true
        expect(cache_store.read(cache_key)).not_to be_nil
        expect(cache_store.read(cache_key)[:market_data]).not_to be_empty
      end
    end

    context 'when all API responses fail' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_raise(StandardError, 'Timeout error')
        allow(MarketData::Adapters::KuCoin).to receive(:new).and_raise(StandardError, 'Timeout error')
        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_raise(StandardError, 'Timeout error')
      end

      it 'returns an error response' do
        result = fetcher.fetch_data
        expect(result[:success]).to be false
        expect(result[:market_data]).to be_empty
        expect(result[:errors].size).to eq(3)
      end

      it 'does not cache the failed response' do
        fetcher.fetch_data
        expect(cache_store.read(cache_key)).to be_nil
      end
    end

    context 'when cached data exists' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:binance_adapter) { instance_spy(MarketData::Adapters::Binance) }
      let(:kucoin_adapter) { instance_spy(MarketData::Adapters::KuCoin) }
      let(:coingecko_adapter) { instance_spy(MarketData::Adapters::CoinGecko) }

      before do
        cache_store.write(cache_key, { success: true, market_data: [mock_market_data], errors: [] }, expires_in: 15)

        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_adapter)
        allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_adapter)
        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coingecko_adapter)
      end

      it 'returns cached data without making API calls' do
        result = fetcher.fetch_data

        expect(result[:market_data].size).to eq(1)

        expect(binance_adapter).not_to have_received(:fetch_market_data)
        expect(kucoin_adapter).not_to have_received(:fetch_market_data)
        expect(coingecko_adapter).not_to have_received(:fetch_market_data)
      end
    end

    context 'when force refresh is enabled' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:force_refresh) { true }

      before do
        cache_store.write(cache_key, { success: true, market_data: [mock_market_data], errors: [] }, expires_in: 15)
      end

      it 'fetches new data and overwrites the cache' do
        new_mock_market_data = { source: 'Binance', price: 46_000 }
        binance_adapter = instance_double(MarketData::Adapters::Binance, fetch_market_data: new_mock_market_data)

        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_adapter)

        result = fetcher.fetch_data
        expect(result[:market_data].first[:price]).to eq(46_000)
        expect(cache_store.read(cache_key)[:market_data].first[:price]).to eq(46_000)
      end
    end

    context 'when cache expires' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      before do
        cache_store.write(cache_key, { success: true, market_data: [mock_market_data], errors: [] }, expires_in: 2)
      end

      it 'fetches new data after cache expiry' do
        sleep 3 # Wait for cache to expire

        new_mock_market_data = { source: 'Binance', price: 47_000 }
        binance_adapter = instance_double(MarketData::Adapters::Binance, fetch_market_data: new_mock_market_data)

        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_adapter)

        result = fetcher.fetch_data
        expect(result[:market_data].first[:price]).to eq(47_000)
      end
    end
  end
end
