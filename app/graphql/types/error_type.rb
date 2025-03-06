# frozen_string_literal: true

module Types
  class ErrorType < Types::BaseObject
    field :error, String, null: false
    field :source, String, null: false
  end
end
