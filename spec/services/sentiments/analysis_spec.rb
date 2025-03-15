# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentiments::Analysis do
  let(:symbol) { 'BTC' }
  let(:options) { { force_refresh: false } }
  let(:analysis) { described_class.new(symbol, options) }

  let(:lunar_crush_mock) { instance_double(Sentiments::Adapters::LunarCrush) }
  let(:santiment_mock) { instance_double(Sentiments::Adapters::Santiment) }
  let(:senticrypt_mock) { instance_double(Sentiments::Adapters::Senticrypt) }
  let(:twitter_mock) { instance_double(Sentiments::Adapters::Twitter) }

  let(:timestamp) { Time.utc(2023, 3, 15, 12, 0, 0) }

  let(:lunar_crush_data) do
    {
      source: :lunar_crush,
      symbol: symbol,
      score: 75.0,
      timestamp: timestamp,
      additional_data: { alt_rank: '1' }
    }
  end

  let(:santiment_data) do
    {
      source: :santiment,
      symbol: symbol,
      score: 80.0,
      timestamp: timestamp,
      additional_data: { metric: 'sentiment_balance' }
    }
  end

  let(:senticrypt_data) do
    {
      source: :senticrypt,
      symbol: symbol,
      score: 0.85,
      timestamp: timestamp,
      additional_data: { sentiment_change: '0.05' }
    }
  end

  let(:twitter_data) do
    {
      source: :twitter,
      symbol: symbol,
      score: 65.0,
      timestamp: timestamp,
      additional_data: { tweet_count: 100 }
    }
  end

  before do
    travel_to timestamp
    Rails.cache.clear

    allow(Rails).to receive(:logger).and_return(instance_double(Logger).as_null_object)

    # Let's not mock the ServicesConfig, use the actual one
    stub_const('ServicesConfig::COMMON_CONFIG', { log_level: 'INFO', timeout: 30 })
  end

  describe 'initialization' do
    it 'initializes with the right adapters' do
      expect(described_class.adapters).to include(Sentiments::Adapters::LunarCrush)
      expect(described_class.adapters).to include(Sentiments::Adapters::Santiment)
      expect(described_class.adapters).to include(Sentiments::Adapters::Senticrypt)
      expect(described_class.adapters).to include(Sentiments::Adapters::Twitter)
    end
  end

  describe '#call' do
    context 'when asset_symbol is provided' do
      before do
        allow(Sentiments::Adapters::LunarCrush).to receive(:new).and_return(lunar_crush_mock)
        allow(lunar_crush_mock).to receive(:fetch_sentiment).and_return(lunar_crush_data)

        allow(Sentiments::Adapters::Santiment).to receive(:new).and_return(santiment_mock)
        allow(santiment_mock).to receive(:fetch_sentiment).and_return(santiment_data)

        allow(Sentiments::Adapters::Senticrypt).to receive(:new).and_return(senticrypt_mock)
        allow(senticrypt_mock).to receive(:fetch_sentiment).and_return(senticrypt_data)

        allow(Sentiments::Adapters::Twitter).to receive(:new).and_return(twitter_mock)
        allow(twitter_mock).to receive(:fetch_sentiment).and_return(twitter_data)
      end

      it 'returns sentiment data from one of the adapters' do
        result = analysis.call
        expect(result).to be_a(Hash)
        expect(result).to have_key(:score)
        expect(result[:score]).to be_a(Numeric)
        expect(result).to have_key(:symbol)
        expect(result[:symbol]).to eq(symbol)
      end

      it 'caches the result' do
        first_result = analysis.call
        second_result = analysis.call

        expect(second_result).to eq(first_result)
        expect(Sentiments::Adapters::LunarCrush).to have_received(:new).once
      end
    end

    context 'when asset_symbol is not provided' do
      let(:symbol) { nil }
      let(:lunar_crush_buzzing) { [{ symbol: 'BTC', score: 75.0 }, { symbol: 'ETH', score: 70.0 }] }
      let(:twitter_buzzing) { [{ symbol: 'BTC', score: 65.0 }, { symbol: 'SOL', score: 60.0 }] }

      before do
        allow(Sentiments::Adapters::LunarCrush).to receive(:new).and_return(lunar_crush_mock)
        allow(lunar_crush_mock).to receive(:fetch_buzzing_coins).and_return(lunar_crush_buzzing)

        allow(Sentiments::Adapters::Santiment).to receive(:new).and_return(santiment_mock)
        allow(santiment_mock).to receive(:fetch_buzzing_coins).and_raise(StandardError.new('Not implemented'))

        allow(Sentiments::Adapters::Senticrypt).to receive(:new).and_return(senticrypt_mock)
        allow(senticrypt_mock).to receive(:fetch_buzzing_coins).and_raise(StandardError.new('Not implemented'))

        allow(Sentiments::Adapters::Twitter).to receive(:new).and_return(twitter_mock)
        allow(twitter_mock).to receive(:fetch_buzzing_coins).and_return(twitter_buzzing)
      end

      it 'attempts to fetch top buzzing coins' do
        analysis.call
        expect(lunar_crush_mock).to have_received(:fetch_buzzing_coins)
        expect(twitter_mock).to have_received(:fetch_buzzing_coins)
      end

      it 'caches the result' do
        analysis.call
        analysis.call
        expect(Sentiments::Adapters::LunarCrush).to have_received(:new).once
      end
    end
  end
end
