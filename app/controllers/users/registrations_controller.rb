# typed: false
# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      if resource.persisted?
        render json: {
          message: 'Account created successfully',
          user: resource,
          token: request.env['warden-jwt_auth.token']
        }, status: :created
      else
        render json: { error: resource.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
