# typed: false
# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :jwt_authenticatable,
         :omniauthable, omniauth_providers: %i[auth0],
                        jwt_revocation_strategy: self

  def self.from_auth0(auth)
    email = auth.dig('info', 'email') || auth.dig('extra', 'raw_info', 'email')
    uid = auth['uid'] || auth.dig('extra', 'raw_info', 'sub') # Fallback to 'sub' if 'uid' is missing

    return nil unless email.present? && uid.present? # Prevent returning nil

    user = find_or_initialize_by(email: email)

    user.update!(
      auth0_uid: uid,
      name: auth.dig('info', 'name') || 'Unknown User',
      password: Devise.friendly_token[0, 20],
      jti: SecureRandom.uuid
    )

    user
  end
end
