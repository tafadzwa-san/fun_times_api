# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::KuCoin do
  subject(:adapter) { described_class.new(symbol, config) }

  let(:symbol) { 'BTC-USDT' }
  let(:config) do
    {
      api_key: 'test_api_key',
      api_secret: 'test_api_secret',
      api_passphrase: 'test_api_passphrase',
      base_url: 'https://api.kucoin.com/api/v1',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  describe '#fetch_market_data' do
    context 'when the request is successful' do
      before do
        stub_request(:get, "#{config[:base_url]}/market/stats?symbol=#{symbol}")
          .to_return(
            status: 200,
            body: {
              code: '200000',
              data: {
                last: '50000.00',
                vol: '1000',
                high: '51000.00',
                low: '49000.00',
                changeRate: '0.02'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the formatted market data' do
        result = adapter.fetch_market_data

        expect(result[:price]).to eq(50_000.00)
        expect(result[:volume]).to eq(1000.0)
        expect(result[:additional_data][:high_24h]).to eq(51_000.00)
        expect(result[:additional_data][:low_24h]).to eq(49_000.00)
        expect(result[:additional_data][:change_24h]).to eq(2.0)
      end
    end

    context 'when market data is missing' do
      before do
        stub_request(:get, "#{config[:base_url]}/market/stats?symbol=#{symbol}")
          .to_return(
            status: 200,
            body: {
              code: '200000',
              data: {}
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::KuCoinError, 'Market data missing')
      end
    end

    context 'when the API returns an error code' do
      before do
        stub_request(:get, "#{config[:base_url]}/market/stats?symbol=#{symbol}")
          .to_return(
            status: 400,
            body: {
              code: '400100',
              msg: 'Invalid symbol'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a KuCoinError with the API error message' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::KuCoinError, 'Request failed: HTTP 400')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, "#{config[:base_url]}/market/stats?symbol=#{symbol}")
          .to_timeout
      end

      it 'wraps the exception in a KuCoinError' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::KuCoinError)
      end
    end
  end
end
