# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::MarketDataQuery, type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{user_jwt_token}" } }

  let(:query) do
    <<~GQL
      query {
        marketDataQuery(coinSymbol: "BTC") {
          success
          marketData {
            source
            symbol
            price
            volume
          }
          errors {
            source
            error
          }
        }
      }
    GQL
  end

  before do
    allow(Services::MarketData::Adapters::Binance).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::MarketData::Adapters::Binance,
                                fetch_market_data: { source: 'Binance', symbol: 'BTC', price: 45_000.00,
                                                     volume: 100_000.00 }
                              ))

    allow(Services::MarketData::Adapters::KuCoin).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::MarketData::Adapters::KuCoin,
                                fetch_market_data: { source: 'KuCoin', symbol: 'BTC', price: 44_800.00,
                                                     volume: 50_000.00 }
                              ))

    allow(Services::MarketData::Adapters::CoinGecko).to receive(:new)
      .with('BTC').and_return(instance_double(
                                Services::MarketData::Adapters::CoinGecko,
                                fetch_market_data: { source: 'CoinGecko', symbol: 'BTC', price: 44_500.00,
                                                     volume: 25_000_000.00 }
                              ))
  end

  describe 'Market Data Query' do
    it 'returns market data for a given coin' do
      post '/graphql', params: { query: query }, headers: headers

      json_response = JSON.parse(response.body)
      market_data = json_response.dig('data', 'marketDataQuery')

      expect(response).to have_http_status(:ok)
      expect(market_data['success']).to be true
      expect(market_data['marketData']).to contain_exactly(
        { 'source' => 'Binance', 'symbol' => 'BTC', 'price' => 45_000.00, 'volume' => 100_000.00 },
        { 'source' => 'KuCoin', 'symbol' => 'BTC', 'price' => 44_800.00, 'volume' => 50_000.00 },
        { 'source' => 'CoinGecko', 'symbol' => 'BTC', 'price' => 44_500.00, 'volume' => 25_000_000.00 }
      )
      expect(market_data['errors']).to eq([])
    end

    context 'when all services fail' do
      before do
        allow(Services::MarketData::Adapters::Binance).to receive(:new).and_raise(StandardError, 'Binance API Error')
        allow(Services::MarketData::Adapters::KuCoin).to receive(:new).and_raise(StandardError, 'KuCoin API Error')
        allow(Services::MarketData::Adapters::CoinGecko).to receive(:new).and_raise(StandardError,
                                                                                    'CoinGecko API Error')
      end

      it 'returns an error response' do
        post '/graphql', params: { query: query }, headers: headers

        json_response = JSON.parse(response.body)
        market_data = json_response.dig('data', 'marketDataQuery')

        expect(response).to have_http_status(:ok)
        expect(market_data['success']).to be false
        expect(market_data['marketData']).to be_empty
        expect(market_data['errors']).to contain_exactly(
          { 'source' => 'Binance', 'error' => 'Binance API Error' },
          { 'source' => 'KuCoin', 'error' => 'KuCoin API Error' },
          { 'source' => 'CoinGecko', 'error' => 'CoinGecko API Error' }
        )
      end
    end
  end

  def user_jwt_token
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
    response.parsed_body['token']
  end
end
