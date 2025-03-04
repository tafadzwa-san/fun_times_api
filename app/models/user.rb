# frozen_string_literal: true

class User < ApplicationRecord
  # Include JTI revocation strategy
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :jwt_authenticatable,
         jwt_revocation_strategy: self
end
