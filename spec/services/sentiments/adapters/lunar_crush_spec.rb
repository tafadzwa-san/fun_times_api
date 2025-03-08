# typed: false
# frozen_string_literal: true

require 'rails_helper'
require 'faraday'

RSpec.describe Sentiments::Adapters::LunarCrush, type: :service do
  subject(:service) { described_class.new('BTC') }

  let(:mock_response) do
    {
      'data' => [{ 'galaxy_score' => 85.6 }]
    }.to_json
  end

  before do
    stub_request(:get, %r{https://api.lunarcrush.com/v2/assets})
      .to_return(status: 200, body: mock_response, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#fetch_sentiment' do
    it 'returns the correct sentiment score' do
      result = service.fetch_sentiment
      expect(result).to eq(source: 'LunarCrush', score: 85.6)
    end
  end
end
