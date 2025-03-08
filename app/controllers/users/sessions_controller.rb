# typed: false
# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      render json: {
        message: 'Logged in successfully',
        user: resource,
        token: request.env['warden-jwt_auth.token']
      }, status: :ok
    end

    def respond_to_on_destroy
      if current_user
        old_jti = current_user.jti
        current_user.update!(jti: SecureRandom.uuid)
        Rails.logger.debug { "🔄 JTI Updated from #{old_jti} → #{current_user.jti}" }

        head :no_content
      else
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
