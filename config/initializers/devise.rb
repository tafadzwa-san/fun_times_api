# typed: false
# frozen_string_literal: true

Devise.setup do |config| # rubocop:disable Metrics/BlockLength
  require 'devise/orm/active_record'

  # Disable session storage for API-only authentication
  config.navigational_formats = []
  config.skip_session_storage = %i[http_auth params_auth cookie_store]

  # Mailer settings
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # Authentication settings
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # Password settings
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.expire_all_remember_me_on_sign_out = true

  # Sign-out configuration
  config.sign_out_via = :delete

  # JWT Configuration
  config.jwt do |jwt|
    jwt.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY', Rails.application.credentials.devise_jwt_secret_key)
    jwt.dispatch_requests = [['POST', %r{^/users/sign_in$}]]
    jwt.revocation_requests = [['DELETE', %r{^/users/sign_out$}]]
    jwt.expiration_time = 1.day.to_i
  end

  # Warden Configuration

  config.warden do |manager|
    manager.intercept_401 = false
    manager.default_strategies(scope: :user).unshift :jwt
    manager.scope_defaults :user, store: false # Ensure sessions are not stored
  end

  if !Rails.env.test? && !Rails.env.production?
    config.omniauth :auth0,
                    ENV.fetch('AUTH0_CLIENT_ID', nil),
                    ENV.fetch('AUTH0_CLIENT_SECRET', nil),
                    ENV.fetch('AUTH0_DOMAIN', nil),
                    callback_path: '/auth/auth0/callback'
  end

  # Auth0 OmniAuth Integration
  # config.omniauth :auth0,
  #                 ENV['AUTH0_CLIENT_ID'],
  #                 ENV['AUTH0_CLIENT_SECRET'],
  #                 client_options: {
  #                   domain: ENV['AUTH0_DOMAIN'],
  #                   authorize_path: '/authorize'
  #                 },
  #                 callback_path: '/auth/auth0/callback'
end

# Move this outside of Devise.setup to avoid conflicts
Warden::JWTAuth.configure do |config|
  config.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY', nil)
end
