# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentiments::Adapters::LunarCrush do
  let(:adapter_config) do
    {
      api_key: 'test_api_key',
      base_url: 'https://api.lunarcrush.com',
      timeout: 30,
      logger: Logger.new(File::NULL),
      log_level: Logger::DEBUG
    }
  end

  let(:symbol) { 'BTC' }
  let(:adapter) { described_class.new(symbol, adapter_config) }

  it_behaves_like 'an adapter initialization', described_class, 'BTC', {
    api_key: 'test_api_key',
    base_url: 'https://api.lunarcrush.com',
    timeout: 30
  }

  describe '#fetch_sentiment' do
    before do
      stub_request(:get, 'https://api.lunarcrush.com/assets')
        .with(query: hash_including({ 'symbol' => 'BTC' }))
        .to_return(
          status: 200,
          body: { 'data' => [{ 'galaxy_score' => '75.0', 'alt_rank' => '1', 'volatility' => '0.5' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fetches sentiment data' do
      response = adapter.fetch_sentiment
      expect(response[:source]).to eq(:lunar_crush)
      expect(response[:symbol]).to eq(symbol)
      expect(response[:score]).to eq(75.0)
      expect(response[:timestamp]).to be_a(Time)
      expect(response[:additional_data][:alt_rank]).to eq('1')
      expect(response[:additional_data][:volatility]).to eq('0.5')
    end

    it 'raises an error if sentiment data is missing' do
      stub_request(:get, 'https://api.lunarcrush.com/assets')
        .with(query: hash_including({ 'symbol' => 'BTC' }))
        .to_return(
          status: 200,
          body: { 'data' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { adapter.fetch_sentiment }.to raise_error(Errors::LunarCrushError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_sentiment }.to raise_error(Errors::LunarCrushError, 'Request failed')
    end
  end

  describe '#fetch_buzzing_coins' do
    before do
      stub_request(:get, 'https://api.lunarcrush.com/assets')
        .with(query: hash_including({ 'limit' => '20', 'sort' => 'galaxy_score' }))
        .to_return(
          status: 200,
          body: {
            'data' => [
              { 'symbol' => 'BTC', 'galaxy_score' => '75.0' },
              { 'symbol' => 'ETH', 'galaxy_score' => '70.0' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fetches buzzing coins data' do
      response = adapter.fetch_buzzing_coins
      expect(response).to be_an(Array)
      expect(response.size).to eq(2)
      expect(response.first[:symbol]).to eq('BTC')
      expect(response.first[:score]).to eq(75.0)
      expect(response.last[:symbol]).to eq('ETH')
      expect(response.last[:score]).to eq(70.0)
    end

    it 'raises an error if buzzing coins data is missing' do
      stub_request(:get, 'https://api.lunarcrush.com/assets')
        .with(query: hash_including({ 'limit' => '20', 'sort' => 'galaxy_score' }))
        .to_return(
          status: 200,
          body: { 'data' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::LunarCrushError, 'Sentiment data missing')
    end

    it 'raises an error if an exception occurs' do
      allow(adapter).to receive(:get).and_raise(StandardError.new('Request failed'))

      expect { adapter.fetch_buzzing_coins }.to raise_error(Errors::LunarCrushError, 'Request failed')
    end
  end
end
