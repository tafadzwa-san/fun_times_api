# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::Binance do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      api_secret: 'test_api_secret',
      base_url: 'https://api.binance.com',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'BTCUSDT' }
  let(:adapter) { described_class.new(symbol, adapter_config) }
  let(:timestamp) { 1_678_900_000_000 }

  before do
    travel_to Time.zone.at(timestamp / 1000.0)

    allow(OpenSSL::HMAC).to receive(:hexdigest).and_return('test_signature')
  end

  it_behaves_like 'an adapter initialization', described_class, 'BTCUSDT', {
    api_key: 'test_api_key',
    api_secret: 'test_api_secret',
    base_url: 'https://api.binance.com'
  }

  describe '#fetch_market_data' do
    context 'when API returns valid data' do
      before do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: hash_including({
                                    'symbol' => symbol,
                                    'timestamp' => timestamp.to_s,
                                    'signature' => 'test_signature'
                                  }),
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-MBX-APIKEY' => adapter_config[:api_key]
            }
          )
          .to_return(
            status: 200,
            body: {
              'symbol' => symbol,
              'price' => '50000.00'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches and standardizes market data' do
        result = adapter.fetch_market_data

        expect(result[:source]).to eq(:binance)
        expect(result[:symbol]).to eq(symbol)
        expect(result[:price]).to eq(50_000.00)
        expect(result[:timestamp]).to be_a(Time)
        expect(result[:volume]).to be_nil
        expect(result[:additional_data]).to eq({})
      end
    end

    context 'when price is missing in the response' do
      before do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: hash_including({
                                    'symbol' => symbol,
                                    'timestamp' => timestamp.to_s,
                                    'signature' => 'test_signature'
                                  })
          )
          .to_return(
            status: 200,
            body: {
              'symbol' => symbol
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a BinanceError' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError, 'Market data missing')
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: hash_including({
                                    'symbol' => symbol,
                                    'timestamp' => timestamp.to_s,
                                    'signature' => 'test_signature'
                                  })
          )
          .to_return(
            status: 400,
            body: {
              code: -1121,
              msg: 'Invalid symbol'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a BinanceError with the error message' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError)
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: hash_including({
                                    'symbol' => symbol,
                                    'timestamp' => timestamp.to_s,
                                    'signature' => 'test_signature'
                                  })
          )
          .to_timeout
      end

      it 'raises a BinanceError with the error message' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError)
      end
    end
  end
end
