# typed: false
# frozen_string_literal: true

require 'rails_helper'
require 'faraday'

RSpec.describe Sentiments::Adapters::Santiment, type: :service do
  subject(:service) { described_class.new('BTC') }

  let(:mock_response) do
    {
      'data' => { 'getSentimentData' => { 'score' => 70.3 } }
    }.to_json
  end

  before do
    stub_request(:post, %r{https://api.santiment.net/graphql})
      .to_return(status: 200, body: mock_response, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#fetch_sentiment' do
    it 'returns the correct sentiment score' do
      result = service.fetch_sentiment
      expect(result).to eq(source: 'Santiment', score: 70.3)
    end
  end
end
