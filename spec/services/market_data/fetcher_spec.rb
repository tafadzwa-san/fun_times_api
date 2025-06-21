# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Fetcher do
  let(:symbol) { 'BTC' }
  let(:options) { { force_refresh: false } }
  let(:fetcher) { described_class.new(symbol, options) }

  let(:binance_mock) { instance_double(MarketData::Adapters::Binance) }
  let(:kucoin_mock) { instance_double(MarketData::Adapters::KuCoin) }
  let(:coin_gecko_mock) { instance_double(MarketData::Adapters::CoinGecko) }

  let(:timestamp) { Time.utc(2023, 3, 15, 12, 0, 0) }

  let(:binance_data) do
    {
      source: :binance,
      symbol: 'BTCUSDT',
      price: 50_000.0,
      volume: nil,
      timestamp: timestamp,
      additional_data: {}
    }
  end

  let(:kucoin_data) do
    {
      source: :kucoin,
      symbol: 'BTC-USDT',
      price: 50_100.0,
      volume: 1000.0,
      timestamp: timestamp,
      additional_data: {
        high_24h: 51_000.0,
        low_24h: 49_000.0,
        change_24h: 2.5
      }
    }
  end

  let(:coin_gecko_data) do
    {
      source: :coin_gecko,
      symbol: 'bitcoin',
      price: 49_900.0,
      volume: nil,
      timestamp: timestamp,
      additional_data: {}
    }
  end

  let(:market_data_config) do
    {
      cache_ttl: 15,
      adapters: {
        binance: {
          base_url: 'https://api.binance.com',
          api_key: 'key',
          api_secret: 'key',
          timeout: 30
        },
        kucoin: {
          base_url: 'https://api.kucoin.com/api/v1',
          timeout: 30
        },
        coin_gecko: {
          api_url: 'https://api.coingecko.com/api/v3',
          timeout: 30
        }
      }
    }
  end

  before do
    travel_to timestamp
    Rails.cache.clear

    allow(Rails).to receive(:logger).and_return(instance_double(Logger).as_null_object)

    allow(ServicesConfig).to receive_messages(
      common_config: { log_level: 'INFO', timeout: 30 },
      market_data_config: market_data_config
    )

    # Reconfigure class with stubbed config after stubbing ServicesConfig
    described_class.configure(market_data_config)
  end

  describe 'initialization' do
    it 'initializes with the right adapters' do
      expect(described_class.adapters).to include(MarketData::Adapters::Binance)
      expect(described_class.adapters).to include(MarketData::Adapters::KuCoin)
      expect(described_class.adapters).to include(MarketData::Adapters::CoinGecko)
    end

    it 'uses the MarketData config' do
      expect(described_class.config).to eq(market_data_config)
    end
  end

  describe '#call' do
    context 'when first adapter succeeds' do
      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_mock)
        allow(binance_mock).to receive(:fetch_market_data).and_return(binance_data)

        allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_mock)
        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coin_gecko_mock)
        allow(kucoin_mock).to receive(:fetch_market_data).and_raise('Should not be called')
        allow(coin_gecko_mock).to receive(:fetch_market_data).and_raise('Should not be called')
      end

      it 'returns data from the first successful adapter' do
        result = fetcher.call
        expect(result).to eq(binance_data)
      end

      it 'caches the result' do
        first_result = fetcher.call
        second_result = fetcher.call

        expect(second_result).to eq(first_result)

        expect(MarketData::Adapters::Binance).to have_received(:new).once
      end
    end

    context 'when first adapter fails but second succeeds' do
      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_mock)
        allow(binance_mock).to receive(:fetch_market_data).and_raise(Errors::BinanceError.new('API error'))

        allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_mock)
        allow(kucoin_mock).to receive(:fetch_market_data).and_return(kucoin_data)

        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coin_gecko_mock)
        allow(coin_gecko_mock).to receive(:fetch_market_data)
          .and_raise(Errors::CoinGeckoError.new('CoinGecko API error'))
      end

      it 'falls back to the next successful adapter' do
        result = fetcher.call
        expect(result).to eq(kucoin_data)
      end
    end

    context 'when all adapters fail' do
      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_mock)
        allow(binance_mock).to receive(:fetch_market_data).and_raise(Errors::BinanceError.new('Binance API error'))

        allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_mock)
        allow(kucoin_mock).to receive(:fetch_market_data).and_raise(Errors::KuCoinError.new('KuCoin API error'))

        allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coin_gecko_mock)
        allow(coin_gecko_mock).to receive(:fetch_market_data)
          .and_raise(Errors::CoinGeckoError.new('CoinGecko API error'))
      end

      it 'returns nil when all adapters fail' do
        result = fetcher.call
        expect(result).to be_nil
      end
    end

    context 'when force_refresh is true' do
      let(:options) { { force_refresh: true } }

      before do
        allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_mock)
        allow(binance_mock).to receive(:fetch_market_data).and_return(binance_data)
      end

      it 'bypasses the cache' do
        first_result = fetcher.call

        new_data = binance_data.merge(price: 51_000.0)
        allow(binance_mock).to receive(:fetch_market_data).and_return(new_data)

        second_result = fetcher.call

        expect(second_result).not_to eq(first_result)
        expect(second_result[:price]).to eq(51_000.0)
        expect(MarketData::Adapters::Binance).to have_received(:new).twice
      end
    end
  end
end
