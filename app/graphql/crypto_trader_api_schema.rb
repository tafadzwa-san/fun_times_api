# frozen_string_literal: true

class CryptoTraderApiSchema < GraphQL::Schema
  query Types::QueryType
  mutation Types::MutationType

  # Enable batch loading for performance
  use GraphQL::Dataloader

  # Set max query size and error limit
  max_query_string_tokens(5000)
  validate_max_errors(100)

  # Relay-style Object Identification
  def self.id_from_object(object, _type_definition, _query_ctx)
    object.to_gid_param
  end

  def self.object_from_id(global_id, _query_ctx)
    GlobalID.find(global_id)
  end
end
