# typed: false
# frozen_string_literal: true

class User < ApplicationRecord
  # Include JTI revocation strategy
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :jwt_authenticatable,
         jwt_revocation_strategy: self

  devise :omniauthable, omniauth_providers: [:auth0] if Rails.env.development?

  before_create :set_jti

  def self.from_auth0(auth_payload)
    user = find_by(auth0_uid: auth_payload['sub']) || find_by(email: auth_payload['email'])

    if user.nil?
      user = create!(
        email: auth_payload['email'],
        name: auth_payload['name'],
        auth0_uid: auth_payload['sub'],
        password: Devise.friendly_token[0, 20],
        jti: SecureRandom.uuid
      )
    else
      user.update!(jti: SecureRandom.uuid)
    end

    user
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
