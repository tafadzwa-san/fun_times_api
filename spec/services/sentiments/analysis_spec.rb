# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::Sentiments::Analysis, type: :service do
  subject(:service) { described_class.new(coin_symbol) }

  let(:coin_symbol) { 'BTC' }

  before do
    allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new)
      .with(coin_symbol).and_return(instance_double(
                                      Services::Sentiments::Adapters::LunarCrush,
                                      fetch_sentiment: { source: 'LunarCrush', score: 85.6 }
                                    ))

    allow(Services::Sentiments::Adapters::Santiment).to receive(:new)
      .with(coin_symbol).and_return(instance_double(
                                      Services::Sentiments::Adapters::Santiment,
                                      fetch_sentiment: { source: 'Santiment', score: 70.3 }
                                    ))

    allow(Services::Sentiments::Adapters::Altfins).to receive(:new)
      .with(coin_symbol).and_return(instance_double(
                                      Services::Sentiments::Adapters::Altfins,
                                      fetch_sentiment: { source: 'Altfins', score: 65.2 }
                                    ))
  end

  describe '#fetch_sentiment' do
    it 'aggregates sentiment data from multiple sources' do
      result = service.fetch_sentiment

      expect(result[:success]).to be true
      expect(result[:sentiment_scores]).to contain_exactly(
        { source: 'LunarCrush', score: 85.6 },
        { source: 'Santiment', score: 70.3 },
        { source: 'Altfins', score: 65.2 }
      )
    end

    context 'when one adapter fails' do
      before do
        allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new)
          .and_raise(StandardError, 'LunarCrush API failure')
      end

      it 'continues processing with other sources' do
        result = service.fetch_sentiment

        expect(result[:success]).to be true
        expect(result[:sentiment_scores]).to include({ source: 'Santiment', score: 70.3 })
        expect(result[:sentiment_scores]).to include({ source: 'Altfins', score: 65.2 })
        expect(result[:sentiment_scores]).not_to include({ source: 'LunarCrush', score: 85.6 })
      end
    end

    context 'when all adapters fail' do
      before do
        allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new).and_raise(StandardError)
        allow(Services::Sentiments::Adapters::Santiment).to receive(:new).and_raise(StandardError)
        allow(Services::Sentiments::Adapters::Altfins).to receive(:new).and_raise(StandardError)
      end

      it 'returns an error response' do
        result = service.fetch_sentiment

        expect(result[:success]).to be false
        expect(result[:error]).to include('No valid sentiment data available').or include('Unexpected error')
      end
    end
  end
end
