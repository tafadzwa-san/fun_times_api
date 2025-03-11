# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::Binance do
  subject(:adapter) { described_class.new(symbol, config) }

  let(:symbol) { 'BTCUSDT' }
  let(:api_key) { 'test_api_key' }
  let(:api_secret) { 'test_api_secret' }
  let(:config) do
    {
      api_key: api_key,
      api_secret: api_secret,
      base_url: 'https://api.binance.com'
    }
  end

  describe '#initialize' do
    it 'initializes with the given symbol and config' do
      expect(adapter.instance_variable_get(:@symbol)).to eq(symbol.upcase)
      expect(adapter.instance_variable_get(:@api_key)).to eq(config[:api_key])
      expect(adapter.instance_variable_get(:@api_secret)).to eq(config[:api_secret])
    end
  end

  describe '#fetch_market_data' do
    let(:timestamp) { 1_672_574_400_000 }

    before do
      allow(Time).to receive(:now).and_return(Time.zone.at(timestamp / 1000.0))

      allow(OpenSSL::HMAC).to receive(:hexdigest)
        .with('sha256', api_secret, "symbol=#{symbol}&timestamp=#{timestamp}")
        .and_return('test_signature')
    end

    context 'when valid credentials and symbol are provided' do
      it 'fetches and standardizes market data' do
        price_data = { 'price' => '50000.00' }

        # Use exact URL, query parameters, and headers
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: {
              'symbol' => symbol,
              'timestamp' => timestamp.to_s,
              'signature' => 'test_signature'
            },
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-MBX-APIKEY' => api_key
            }
          )
          .to_return(
            status: 200,
            body: price_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = adapter.fetch_market_data

        expect(result[:price]).to eq(50_000.00)
        expect(result[:volume]).to be_nil
        expect(result[:additional_data]).to eq({})
      end
    end

    context 'when price is missing in the response' do
      it 'raises a BinanceError' do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: {
              'symbol' => symbol,
              'timestamp' => timestamp.to_s,
              'signature' => 'test_signature'
            },
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-MBX-APIKEY' => api_key
            }
          )
          .to_return(
            status: 200,
            body: {}.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect { adapter.fetch_market_data }.to raise_error(Errors::BinanceError, 'Market data missing')
      end
    end

    context 'when an error occurs during API call' do
      it 'wraps the error in a BinanceError' do
        stub_request(:get, 'https://api.binance.com/api/v3/ticker/price')
          .with(
            query: {
              'symbol' => symbol,
              'timestamp' => timestamp.to_s,
              'signature' => 'test_signature'
            },
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-MBX-APIKEY' => api_key
            }
          )
          .to_raise(StandardError.new('API connection error'))

        expect do
          adapter.fetch_market_data
        end.to raise_error(Errors::BinanceError, 'Request failed: API connection error')
      end
    end
  end
end
