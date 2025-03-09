# typed: false
# frozen_string_literal: true

module Types
  class ErrorType < Types::BaseObject
    field :error, String
    field :source, String
  end
end
