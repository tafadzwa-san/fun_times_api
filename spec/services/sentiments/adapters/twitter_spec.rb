# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentiments::Adapters::Twitter do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.twitter.com',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'BTC' }
  let(:adapter) { described_class.new(symbol, adapter_config) }

  it_behaves_like 'an adapter initialization', described_class, 'BTC', {
    api_key: 'test_api_key',
    base_url: 'https://api.twitter.com',
    timeout: 30
  }

  describe '#fetch_sentiment' do
    it 'fetches sentiment data' do
      stub_request(:get, 'https://api.twitter.com/tweets/search/recent')
        .with(query: hash_including({ 'query' => 'BTC OR #BTC', 'max_results' => '100' }))
        .to_return(
          status: 200,
          body: '{"data":[{"text":"BTC is great!"},{"text":"I love BTC"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      response = adapter.fetch_sentiment
      expect(response[:source]).to eq(:twitter)
      expect(response[:symbol]).to eq(symbol)
      expect(response[:score]).to be_a(Numeric)
      expect(response[:timestamp]).to be_a(Time)
      expect(response[:additional_data][:tweet_count]).to eq(2)
    end

    it 'raises an error if sentiment data is missing' do
      stub_request(:get, 'https://api.twitter.com/tweets/search/recent')
        .with(query: hash_including({ 'query' => 'BTC OR #BTC', 'max_results' => '100' }))
        .to_return(
          status: 200,
          body: '{"data":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { adapter.fetch_sentiment }.to raise_error(Errors::TwitterError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_sentiment }.to raise_error(Errors::TwitterError, 'Request failed')
    end
  end

  describe '#fetch_buzzing_coins' do
    it 'fetches buzzing coins' do
      stub_request(:get, 'https://api.twitter.com/tweets/search/recent')
        .with(query: hash_including({ 'query' => '#crypto OR #cryptocurrency', 'max_results' => '100' }))
        .to_return(
          status: 200,
          body: '{"data":[{"text":"BTC is great!"},{"text":"ETH is amazing!"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      response = adapter.fetch_buzzing_coins
      expect(response).to be_an(Array)
      expect(response.size).to be >= 1
      expect(response.first[:symbol]).to eq('BTC')
      expect(response.first[:score]).to be_a(Numeric)
    end

    it 'raises an error if sentiment data is missing' do
      stub_request(:get, 'https://api.twitter.com/tweets/search/recent')
        .with(query: hash_including({ 'query' => '#crypto OR #cryptocurrency', 'max_results' => '100' }))
        .to_return(status: 200, body: '{"data":[]}', headers: { 'Content-Type' => 'application/json' })

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::TwitterError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::TwitterError, 'Request failed')
    end
  end
end
