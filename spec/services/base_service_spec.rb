# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseService do
  let(:binance_data) do
    {
      source: :binance,
      symbol: 'BTCUSDT',
      price: 50_000.0,
      volume: nil,
      timestamp: Time.now.utc,
      additional_data: {}
    }
  end

  let(:kucoin_data) do
    {
      source: :kucoin,
      symbol: 'BTC-USDT',
      price: 50_100.0,
      volume: 1000.0,
      timestamp: Time.now.utc,
      additional_data: {
        high_24h: 51_000.0,
        low_24h: 49_000.0,
        change_24h: 2.5
      }
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

  let(:binance_mock) { instance_double(MarketData::Adapters::Binance) }
  let(:kucoin_mock) { instance_double(MarketData::Adapters::KuCoin) }
  let(:coin_gecko_mock) { instance_double(MarketData::Adapters::CoinGecko) }

  let(:asset_symbol) { 'BTC' }
  let(:options) { { force_refresh: false } }

  let(:service) { MarketData::Fetcher.new(asset_symbol, options) }

  before do
    Rails.cache.clear

    allow(Rails).to receive(:logger).and_return(instance_double(Logger).as_null_object)
    allow(ServicesConfig).to receive_messages(common_config: {
                                                log_level: 'INFO',
                                                timeout: 30
                                              }, market_data_config: market_data_config)

    allow(MarketData::Adapters::Binance).to receive(:new).and_return(binance_mock)
    allow(MarketData::Adapters::KuCoin).to receive(:new).and_return(kucoin_mock)
    allow(MarketData::Adapters::CoinGecko).to receive(:new).and_return(coin_gecko_mock)

    allow(binance_mock).to receive(:fetch_market_data).and_return(binance_data)
    allow(kucoin_mock).to receive(:fetch_market_data).and_return(kucoin_data)

    allow(coin_gecko_mock).to receive(:fetch_market_data)
      .and_raise(Errors::CoinGeckoError.new('API rate limit exceeded'))
  end

  describe 'class methods and module behavior' do
    it 'extends including classes with required methods' do
      expect(MarketData::Fetcher).to respond_to(:use_adapters)
      expect(MarketData::Fetcher).to respond_to(:configure)
    end

    it 'configures the service with adapters' do
      expect(MarketData::Fetcher.adapters).to include(MarketData::Adapters::Binance)
      expect(MarketData::Fetcher.adapters).to include(MarketData::Adapters::KuCoin)
      expect(MarketData::Fetcher.adapters).to include(MarketData::Adapters::CoinGecko)
    end

    it 'configures the service with settings' do
      expect(MarketData::Fetcher.config).to include(:adapters)
      expect(MarketData::Fetcher.config).to include(:cache_ttl)
      expect(MarketData::Fetcher.config[:adapters]).to include(:binance)
      expect(MarketData::Fetcher.config[:adapters]).to include(:kucoin)
    end
  end

  describe '#initialize' do
    it 'initializes with asset symbol and options' do
      expect(service).to be_a(MarketData::Fetcher)
      expect(service.instance_variable_get(:@asset_symbol)).to eq('BTC')
      expect(service.instance_variable_get(:@force_refresh)).to be(false)
    end

    it 'uses the service config from the class' do
      expect(service.instance_variable_get(:@config)).to eq(MarketData::Fetcher.config)
    end
  end

  describe '#call' do
    context 'when all adapters are available' do
      it 'returns data from an adapter' do
        result = service.call

        expect([binance_data, kucoin_data]).to include(result)
      end
    end

    context 'when primary adapter fails' do
      before do
        allow(binance_mock).to receive(:fetch_market_data).and_raise(Errors::BinanceError.new('API error'))
      end

      it 'falls back to next adapter' do
        result = service.call
        expect(result).to eq(kucoin_data)
      end
    end

    context 'when all adapters fail' do
      before do
        allow(binance_mock).to receive(:fetch_market_data).and_raise(Errors::BinanceError.new('API error'))
        allow(kucoin_mock).to receive(:fetch_market_data).and_raise(Errors::KuCoinError.new('API error'))
        allow(coin_gecko_mock).to receive(:fetch_market_data)
          .and_raise(Errors::CoinGeckoError.new('API rate limit exceeded'))
      end

      it 'returns nil' do
        result = service.call
        expect(result).to be_nil
      end
    end
  end

  describe 'caching behavior' do
    it 'caches results between calls' do
      first_result = service.call

      modified_data = binance_data.merge(price: 51_000.0)
      allow(binance_mock).to receive(:fetch_market_data).and_return(modified_data)

      second_result = service.call
      expect(first_result).to eq(second_result)
    end

    it 'bypasses cache with force_refresh option' do
      service_with_refresh = MarketData::Fetcher.new(asset_symbol, force_refresh: true)

      first_result = service_with_refresh.call

      modified_data = binance_data.merge(price: 51_000.0)
      allow(binance_mock).to receive(:fetch_market_data).and_return(modified_data)

      second_result = service_with_refresh.call

      expect(first_result).not_to eq(second_result)
      expect(second_result[:price]).to eq(51_000.0)
    end
  end

  describe 'response format' do
    context 'with successful data fetch' do
      it 'returns properly formatted data' do
        result = service.call

        expect(result).to include(:source)
        expect(result).to include(:symbol)
        expect(result).to include(:price)
        expect(result).to include(:timestamp)
      end
    end
  end
end
