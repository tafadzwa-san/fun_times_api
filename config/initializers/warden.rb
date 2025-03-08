# typed: false
# frozen_string_literal: true

Warden::JWTAuth.configure do |config|
  config.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY')
end
