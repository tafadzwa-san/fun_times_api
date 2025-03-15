# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentiments::Adapters::Senticrypt do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.senticrypt.com',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'BTC' }
  let(:adapter) { described_class.new(symbol, adapter_config) }

  it_behaves_like 'an adapter initialization', described_class, 'BTC', {
    api_key: 'test_api_key',
    base_url: 'https://api.senticrypt.com',
    timeout: 30
  }

  describe '#fetch_sentiment' do
    it 'fetches sentiment data' do
      stub_request(:get, 'https://api.senticrypt.com/sentiment')
        .with(query: hash_including({ 'symbol' => 'BTC' }))
        .to_return(
          status: 200,
          body: '{"data":[{"sentiment_score":"0.75", "sentiment_change":"0.05"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      response = adapter.fetch_sentiment
      expect(response[:source]).to eq(:senticrypt)
      expect(response[:symbol]).to eq(symbol)
      expect(response[:score]).to eq(0.75)
      expect(response[:timestamp]).to be_a(Time)
      expect(response[:additional_data][:sentiment_change]).to eq('0.05')
    end

    it 'raises an error if sentiment data is missing' do
      stub_request(:get, 'https://api.senticrypt.com/sentiment')
        .with(query: hash_including({ 'symbol' => 'BTC' }))
        .to_return(status: 200, body: '{"data":[]}', headers: { 'Content-Type' => 'application/json' })

      expect { adapter.fetch_sentiment }.to raise_error(Errors::SenticryptError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_sentiment }.to raise_error(Errors::SenticryptError, 'Request failed')
    end
  end

  describe '#fetch_buzzing_coins' do
    it 'fetches trending coins' do
      stub_request(:get, 'https://api.senticrypt.com/trending')
        .with(query: hash_including({ 'limit' => '20' }))
        .to_return(
          status: 200,
          body: '{"data":[{"symbol":"BTC","sentiment_score":"0.75"},{"symbol":"ETH","sentiment_score":"0.70"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      response = adapter.fetch_buzzing_coins
      expect(response).to be_an(Array)
      expect(response.size).to eq(2)
      expect(response.first[:symbol]).to eq('BTC')
      expect(response.first[:score]).to eq(0.75)
    end

    it 'raises an error if trending data is missing' do
      stub_request(:get, 'https://api.senticrypt.com/trending')
        .with(query: hash_including({ 'limit' => '20' }))
        .to_return(status: 200, body: '{"data":[]}', headers: { 'Content-Type' => 'application/json' })

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::SenticryptError, 'Trending data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::SenticryptError, 'Request failed')
    end
  end
end
