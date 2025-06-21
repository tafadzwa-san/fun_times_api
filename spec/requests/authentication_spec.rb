# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Authentication', type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe 'POST /users/sign_in' do
    it 'logs in and returns a JWT token' do
      post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }, as: :json

      json_response = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json_response['token']).to be_present
      expect(json_response['user']['email']).to eq(user.email)
    end
  end

  describe 'DELETE /users/sign_out' do
    let(:token) do
      post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }, as: :json
      response.parsed_body['token']
    end

    it 'logs out the user and revokes the token' do
      old_jti = user.jti

      delete '/users/sign_out', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:no_content)
      user.reload
      expect(user.jti).not_to eq(old_jti) # Ensure JTI changes after logout
    end
  end
end
