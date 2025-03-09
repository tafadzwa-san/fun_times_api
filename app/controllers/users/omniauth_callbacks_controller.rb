# typed: false
# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def auth0
      auth = request.env['omniauth.auth']

      # Ensure user is found before proceeding
      user = User.from_auth0(auth)

      if user.present? && user.persisted?
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: 'Auth0') if is_navigational_format?
      else
        redirect_to root_path, alert: 'Authentication failed. Please try again.' # rubocop:disable Rails/I18nLocaleTexts
      end
    end
  end
end
