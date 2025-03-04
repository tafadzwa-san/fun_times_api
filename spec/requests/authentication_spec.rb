# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  let!(:jwt_token) { user_jwt_token }
  let(:auth_headers) { { 'Authorization' => "Bearer #{jwt_token}" } }

  describe 'POST /users/sign_in' do
    it 'logs in a user and returns a JWT token' do
      expect(response).to have_http_status(:ok)
      expect(jwt_token).not_to be_nil
    end

    it 'rejects invalid credentials' do
      post '/users/sign_in', params: { user: { email: user.email, password: 'wrongpassword' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /users/sign_up' do
    it 'creates a new user and returns a JWT token' do
      post '/users', params: { user: { email: 'newuser@example.com', password: 'password123' } }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to have_key('token')
    end
  end

  describe 'GET /api/trades' do
    it 'allows access with a valid token' do
      get '/api/trades', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'denies access without a token' do
      get '/api/trades'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'logs out the user by revoking the token' do
      decoded_token_before_logout = JWT.decode(jwt_token, ENV.fetch('DEVISE_JWT_SECRET_KEY'), true,
                                               algorithm: 'HS256').first
      user_jti_before = decoded_token_before_logout['jti']

      delete '/users/sign_out', headers: auth_headers
      expect(response).to have_http_status(:no_content)

      user.reload
      expect(user_jti_before).not_to eq(user.jti)

      get '/api/trades', headers: auth_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  private

  def user_jwt_token
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }
    response.parsed_body['token']
  end
end
