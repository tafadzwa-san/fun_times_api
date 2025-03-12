# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::Adapters::CoinGecko do
  subject(:adapter) { described_class.new(symbol, config) }

  let(:config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.coingecko.com/api/v3',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'bitcoin' }

  describe '#fetch_market_data' do
    it 'fetches market data' do
      stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
        .with(
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'X-Cg-Pro-Api-Key' => 'test_api_key'
          }
        )
        .to_return(status: 200, body: '{"BITCOIN":{"usd":50000.00}}', headers: { 'Content-Type' => 'application/json' })

      response = adapter.fetch_market_data
      expect(response[:price]).to eq(50_000.00)
    end

    it 'raises an error if market data is missing' do
      stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
        .with(
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'X-Cg-Pro-Api-Key' => 'test_api_key'
          }
        )
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      expect { adapter.fetch_market_data }.to raise_error(Errors::CoinGeckoError, 'Market data missing')
    end

    it 'raises an error if an exception occurs' do
      stub_request(:get, 'https://api.coingecko.com/api/v3/simple/price?ids=BITCOIN&vs_currencies=usd')
        .with(
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'X-Cg-Pro-Api-Key' => 'test_api_key'
          }
        )
        .to_timeout

      expect { adapter.fetch_market_data }.to raise_error(Errors::CoinGeckoError)
    end
  end
end
