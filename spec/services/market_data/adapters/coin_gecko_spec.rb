# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::CoinGecko do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.coingecko.com/api/v3',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'bitcoin' }
  let(:adapter) { described_class.new(symbol, adapter_config) }
  let(:timestamp) { Time.utc(2023, 3, 15, 12, 0, 0) }

  before do
    travel_to timestamp
  end

  it_behaves_like 'an adapter initialization', described_class, 'bitcoin', {
    api_key: 'test_api_key',
    base_url: 'https://api.coingecko.com/api/v3'
  }

  describe '#fetch_market_data' do
    context 'when the request is successful' do
      before do
        stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Cg-Pro-Api-Key' => adapter_config[:api_key]
            }
          )
          .to_return(
            status: 200,
            body: '{"BITCOIN":{"usd":50000.00}}',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns formatted market data' do
        result = adapter.fetch_market_data

        expect(result[:source]).to eq(:coin_gecko)
        expect(result[:symbol]).to eq('BITCOIN')
        expect(result[:price]).to eq(50_000.00)
        expect(result[:timestamp]).to be_a(Time)
        expect(result[:volume]).to be_nil
        expect(result[:additional_data]).to eq({})
      end
    end

    context 'when market data is missing' do
      before do
        stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Cg-Pro-Api-Key' => adapter_config[:api_key]
            }
          )
          .to_return(
            status: 200,
            body: '{}',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error if market data is missing' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::CoinGeckoError, 'Market data missing')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Cg-Pro-Api-Key' => adapter_config[:api_key]
            }
          )
          .to_timeout
      end

      it 'raises an error if an exception occurs' do
        expect { adapter.fetch_market_data }.to raise_error(Errors::CoinGeckoError)
      end
    end
  end
end
