# frozen_string_literal: true

require 'rails_helper'
require 'faraday'

RSpec.describe Services::Sentiments::Adapters::Altfins, type: :service do
  subject(:service) { described_class.new('BTC') }

  let(:mock_response) do
    { 'sentiment_score' => 65.2 }.to_json
  end

  before do
    stub_request(:get, %r{https://api.altfins.com/v1/sentiment})
      .to_return(status: 200, body: mock_response, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#fetch_sentiment' do
    it 'returns the correct sentiment score' do
      result = service.fetch_sentiment
      expect(result).to eq(source: 'Altfins', score: 65.2)
    end
  end
end
