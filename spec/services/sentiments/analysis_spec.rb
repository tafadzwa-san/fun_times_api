# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::Sentiments::Analysis, type: :service do
  subject(:service) { described_class.new('BTC') }

  before do
    allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::Sentiments::Adapters::LunarCrush,
                                fetch_sentiment: { source: 'LunarCrush', score: 85.6 }
                              ))

    allow(Services::Sentiments::Adapters::Santiment).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::Sentiments::Adapters::Santiment,
                                fetch_sentiment: { source: 'Santiment', score: 70.3 }
                              ))

    allow(Services::Sentiments::Adapters::Senticrypt).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::Sentiments::Adapters::Senticrypt,
                                fetch_sentiment: { source: 'SentiCrypt', score: 60.5 }
                              ))
  end

  describe '#fetch_sentiment' do
    it 'aggregates sentiment from multiple sources' do
      result = service.fetch_sentiment
      expect(result[:success]).to be true
      expect(result[:sentiment_scores]).to contain_exactly(
        { source: 'LunarCrush', score: 85.6 },
        { source: 'Santiment', score: 70.3 },
        { source: 'SentiCrypt', score: 60.5 }
      )
    end

    context 'when all adapters fail' do
      before do
        allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new).and_raise(StandardError, 'LunarCrush Error')
        allow(Services::Sentiments::Adapters::Santiment).to receive(:new).and_raise(StandardError, 'Santiment Error')
        allow(Services::Sentiments::Adapters::Senticrypt).to receive(:new).and_raise(StandardError, 'SentiCrypt Error')
      end

      it 'returns an error response' do
        result = service.fetch_sentiment
        expect(result[:success]).to be false
        expect(result[:sentiment_scores]).to eq([])
        expect(result[:error]).to include('LunarCrush Error', 'Santiment Error', 'SentiCrypt Error')
      end
    end
  end
end
