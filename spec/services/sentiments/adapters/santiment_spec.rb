# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentiments::Adapters::Santiment do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.santiment.net/graphql',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'BTC' }
  let(:adapter) { described_class.new(symbol, adapter_config) }

  it_behaves_like 'an adapter initialization', described_class, 'BTC', {
    api_key: 'test_api_key',
    base_url: 'https://api.santiment.net/graphql',
    timeout: 30
  }

  describe '#fetch_sentiment' do
    it 'fetches sentiment data' do
      stub_request(:post, 'https://api.santiment.net/graphql')
        .to_return(
          status: 200,
          body: '{"data":{"getMetric":{"timeseriesData":[{"datetime":"2023-01-01T00:00:00Z","value":"0.75"}]}}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      response = adapter.fetch_sentiment
      expect(response[:source]).to eq(:santiment)
      expect(response[:symbol]).to eq(symbol)
      expect(response[:score]).to eq(75.0)
      expect(response[:timestamp]).to be_a(Time)
      expect(response[:additional_data][:timestamp]).to eq('2023-01-01T00:00:00Z')
      expect(response[:additional_data][:metric]).to eq('sentiment_balance')
    end

    it 'raises an error if sentiment data is missing' do
      stub_request(:post, 'https://api.santiment.net/graphql')
        .to_return(
          status: 200,
          body: '{"data":{"getMetric":{"timeseriesData":[]}}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { adapter.fetch_sentiment }.to raise_error(Errors::SantimentError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:post).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_sentiment }.to raise_error(Errors::SantimentError, 'Request failed')
    end
  end
end
