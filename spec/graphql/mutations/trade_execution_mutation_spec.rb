# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::TradeExecutionMutation, type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{user_jwt_token}" } }

  let(:mutation) do
    <<~GQL
      mutation($input: TradeExecutionInput!) {
        tradeExecution(input: $input) {
          success
          trade {
            source
            orderId
            executedPrice
            quantity
            status
          }
          errors {
            source
            error
          }
        }
      }
    GQL
  end

  let(:variables) do
    {
      input: {
        symbol: 'BTC-USDT',
        action: 'buy',
        quantity: 0.5,
        preferred_exchange: 'Binance'
      }
    }
  end

  before do
    allow(Services::Trading::Adapters::Binance).to receive(:new).and_return(instance_double(
                                                                              Services::Trading::Adapters::Binance,
                                                                              place_order: {
                                                                                source: 'Binance',
                                                                                order_id: '123456',
                                                                                executed_price: 45_000.00,
                                                                                quantity: 0.5,
                                                                                status: 'FILLED'
                                                                              }
                                                                            ))
  end

  describe 'Trade Execution Mutation' do
    it 'executes a trade and returns trade details' do
      post '/graphql', params: { query: mutation, variables: variables.to_json }, headers: headers

      json_response = JSON.parse(response.body)
      trade_data = json_response.dig('data', 'tradeExecution')

      puts mutation
      puts json_response
      expect(response).to have_http_status(:ok)
      expect(trade_data['success']).to be true
      expect(trade_data['trade']).to include(
        'source' => 'Binance',
        'orderId' => '123456',
        'executedPrice' => 45_000.00,
        'quantity' => 0.5,
        'status' => 'FILLED'
      )
      expect(trade_data['errors']).to eq([])
    end

    context 'when an error occurs' do
      before do
        allow(Services::Trading::Adapters::Binance).to receive(:new).and_raise(StandardError, 'Unexpected trade error')
      end

      it 'returns an error message' do
        post '/graphql', params: { query: mutation, variables: variables.to_json }, headers: headers

        json_response = JSON.parse(response.body)
        trade_data = json_response.dig('data', 'tradeExecution')

        expect(response).to have_http_status(:ok)
        expect(trade_data['success']).to be false
        expect(trade_data['trade']).to be_nil
        expect(trade_data['errors']).to contain_exactly(
          { 'source' => 'TradeExecutionMutation', 'error' => 'Unexpected trade error' }
        )
      end
    end
  end

  private

  def user_jwt_token
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
    response.parsed_body['token']
  end
end
