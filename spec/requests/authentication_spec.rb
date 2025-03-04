# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /users/sign_in' do
    it 'logs in a user and returns a JWT token' do # rubocop:disable RSpec/MultipleExpectations
      post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key('token')
    end

    it 'rejects invalid credentials' do
      post '/users/sign_in', params: { user: { email: user.email, password: 'wrongpassword' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /users/sign_up' do
    it 'creates a new user and returns a JWT token' do # rubocop:disable RSpec/MultipleExpectations
      post '/users', params: { user: { email: 'newuser@example.com', password: 'password123' } }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to have_key('token')
    end
  end

  describe 'GET /api/trades' do
    let(:auth_headers) { { 'Authorization' => "Bearer #{user_jwt_token}" } }

    it 'allows access with valid token' do
      get '/api/trades', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'denies access without a token' do
      get '/api/trades'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # describe 'DELETE /users/sign_out' do
  #   let(:auth_headers) { { 'Authorization' => "Bearer #{user_jwt_token}" } }

  #   it 'logs out the user by revoking the token' do
  #     delete '/users/sign_out', headers: auth_headers
  #     expect(response).to have_http_status(:no_content)

  #     # Ensure token is revoked by trying to use it again
  #     get '/api/trades', headers: auth_headers
  #     expect(response).to have_http_status(:unauthorized)
  #   end
  # end

  private

  def generate_jwt(user)
    secret = ENV.fetch('DEVISE_JWT_SECRET_KEY')
    payload = { sub: user.id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, secret, 'HS256')
  end

  def user_jwt_token
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
    response.parsed_body['token']
  end
end
