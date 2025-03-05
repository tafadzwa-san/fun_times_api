# frozen_string_literal: true

class GraphqlController < ApplicationController
  skip_before_action :authenticate_user!, only: [:execute]

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    result = CryptoTraderApiSchema.execute(
      query,
      variables: variables,
      context: { current_user: current_user },
      operation_name: operation_name
    )

    render json: result
  rescue StandardError => e
    render json: { error: "GraphQL Execution Error: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      ambiguous_param.present? ? JSON.parse(ambiguous_param) : {}
    when Hash, nil
      ambiguous_param
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
