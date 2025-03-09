# typed: false
# frozen_string_literal: true

class GraphqlController < ApplicationController
  before_action :authenticate_user!

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = { current_user: current_user }

    result = CryptoTraderApiSchema.execute(query, variables: variables, context: context,
                                                  operation_name: operation_name)
    render json: result
  rescue StandardError => e
    handle_error_in_development(e)
  end

  private

  def prepare_variables(variables_param)
    case variables_param
    when String
      JSON.parse(variables_param) || {}
    when Hash, ActionController::Parameters
      variables_param
    else
      {}
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { errors: [{ message: error.message, backtrace: error.backtrace }] }, status: :internal_server_error
  end
end
