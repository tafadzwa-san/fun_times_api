# frozen_string_literal: true

class GraphqlController < ApplicationController
  include Authentication

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    result = CryptoTraderSchema.execute(
      query,
      variables: variables,
      context: { current_user: current_user },
      operation_name: operation_name
    )

    render json: result
  end
end
