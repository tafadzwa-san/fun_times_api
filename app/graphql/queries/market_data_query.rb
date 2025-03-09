# typed: false
# frozen_string_literal: true

module Queries
  class MarketDataQuery < Queries::BaseQuery
    type Types::MarketDataResultType, null: false
    argument :coin_symbol, String, required: true

    def resolve(coin_symbol:)
      result = MarketData::Fetcher.new(coin_symbol).fetch_data

      {
        success: result[:success],
        market_data: result[:market_data],
        errors: result[:errors] || []
      }
    rescue StandardError => e
      {
        success: false,
        market_data: [],
        errors: [{ source: 'MarketDataQuery', error: e.message }]
      }
    end
  end
end
