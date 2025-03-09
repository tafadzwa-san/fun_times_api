# typed: false
# frozen_string_literal: true

# config/initializers/omniauth.rb
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.before_request_phase = lambda { |env|
  env['rack.session'] ||= {} # Ensure session exists for OmniAuth
}
OmniAuth.config.request_validation_phase = ->(env) { env }
OmniAuth.config.on_failure = ->(env) { OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
OmniAuth.config.failure_raise_out_environments = []
