# frozen_string_literal: true

module Api
  class TradesController < ApplicationController
    include Authentication

    def index
      render json: { message: 'Trades API is working' }, status: :ok
    end
  end
end
