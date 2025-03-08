# typed: false
# frozen_string_literal: true

OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true

# Disable session storage since we are using JWT authentication
OmniAuth.config.logger = Rails.logger
OmniAuth.config.request_validation_phase = ->(env) { env }
OmniAuth.config.on_failure = ->(env) { OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
OmniAuth.config.before_request_phase = lambda { |env|
  env['rack.session'] ||= {} # Ensure session exists for OmniAuth
}
