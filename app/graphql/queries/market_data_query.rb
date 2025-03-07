# frozen_string_literal: true

require_relative '../../services/market_data/fetcher'

module Queries
  class MarketDataQuery < Queries::BaseQuery
    type Types::MarketDataResultType, null: false

    argument :coin_symbol, String, required: true

    def resolve(coin_symbol:)
      Services::MarketData::Fetcher.new(coin_symbol).fetch_data
    rescue StandardError => e
      GraphQL::ExecutionError.new("Error fetching market data: #{e.message}")
    end
  end
end
