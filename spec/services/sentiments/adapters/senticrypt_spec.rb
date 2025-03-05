# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::Sentiments::Adapters::Senticrypt, type: :service do
  subject(:adapter) { described_class.new('BTC') }

  let(:api_url) { 'https://api.senticrypt.com/v1/sentiment?symbol=BTC' }

  context 'when successful API request' do
    before do
      stub_request(:get, api_url)
        .to_return(status: 200, body: { sentiment_score: 60.5 }.to_json)
    end

    it 'returns sentiment score' do
      result = adapter.fetch_sentiment
      expect(result).to eq(source: 'SentiCrypt', score: 60.5)
    end
  end

  context 'when API request failure' do
    before do
      stub_request(:get, api_url).to_return(status: 500)
    end

    it 'returns error' do
      result = adapter.fetch_sentiment
      expect(result[:error]).to eq('SentiCrypt request failed')
    end
  end
end
