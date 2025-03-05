# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::SentimentQuery, type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{user_jwt_token}" } }

  let(:query) do
    <<~GQL
      query {
        sentimentQuery(coinSymbol: "BTC") {
          success
          sentimentScores {
            source
            score
          }
          error
        }
      }
    GQL
  end

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
                                fetch_sentiment: { source: 'Senticrypt', score: 65.2 }
                              ))
  end

  describe 'Sentiment Query' do
    it 'returns sentiment data for a given coin' do
      post '/graphql', params: { query: query }, headers: headers

      json_response = JSON.parse(response.body)
      sentiment_data = json_response.dig('data', 'sentimentQuery')

      expect(response).to have_http_status(:ok)
      expect(sentiment_data['success']).to be true
      expect(sentiment_data['sentimentScores']).to contain_exactly(
        { 'source' => 'LunarCrush', 'score' => 85.6 },
        { 'source' => 'Santiment', 'score' => 70.3 },
        { 'source' => 'Senticrypt', 'score' => 65.2 }
      )
      expect(sentiment_data['error']).to be_nil
    end

    context 'when all services fail' do
      before do
        allow(Services::Sentiments::Adapters::LunarCrush).to receive(:new)
          .and_return(instance_double(Services::Sentiments::Adapters::LunarCrush,
                                      fetch_sentiment: { source: 'LunarCrush', error: 'API Timeout' }))

        allow(Services::Sentiments::Adapters::Santiment).to receive(:new)
          .and_return(instance_double(Services::Sentiments::Adapters::Santiment,
                                      fetch_sentiment: { source: 'Santiment', error: 'Invalid API Key' }))

        allow(Services::Sentiments::Adapters::Senticrypt).to receive(:new)
          .and_return(instance_double(Services::Sentiments::Adapters::Senticrypt,
                                      fetch_sentiment: { source: 'Senticrypt', error: 'Service Unavailable' }))
      end

      it 'returns an error message with details' do
        post '/graphql', params: { query: query }, headers: headers

        json_response = JSON.parse(response.body)
        sentiment_data = json_response.dig('data', 'sentimentQuery')

        expect(response).to have_http_status(:ok)
        expect(sentiment_data['success']).to be false
        expect(sentiment_data['sentimentScores']).to eq([])
        expect(sentiment_data['error']).to eq('API Timeout, Invalid API Key, Service Unavailable')
      end
    end
  end

  private

  def user_jwt_token
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
    response.parsed_body['token']
  end
end
