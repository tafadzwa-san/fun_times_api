# frozen_string_literal: true

class AddAuth0UidAndJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :auth0_uid, :string
    add_index :users, :auth0_uid
    add_column :users, :jti, :string, null: false, default: SecureRandom.uuid
    add_index :users, :jti
    add_column :users, :name, :string
  end
end
