# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    auth_header = request.headers['Authorization']
    token = auth_header&.split&.last

    if token.blank?
      render json: { error: 'Missing token' }, status: :unauthorized
      return
    end

    decoded_payload = JsonWebToken.verify(token)

    unless decoded_payload
      render json: { error: 'Invalid token' }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: decoded_payload['sub'])
    render json: { error: 'User not found' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
