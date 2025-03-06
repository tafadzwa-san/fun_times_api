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
    context 'when one adapter fails' do
      before do
        allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new).and_raise(Errors::LunarCrushError,
                                                                                     'LunarCrush Error')
      end

      it 'continues processing with other sources' do
        result = service.fetch_sentiment

        expect(result[:success]).to be true
        expect(result[:sentiment_scores]).to include(
          { source: 'Santiment', score: 70.3 },
          { source: 'SentiCrypt', score: 60.5 }
        )
        expect(result[:sentiment_scores]).not_to include(hash_including(source: 'LunarCrush'))
        expect(result[:errors]).to include({ source: 'LunarCrush', error: 'LunarCrush Error' })
      end
    end
  end
end
