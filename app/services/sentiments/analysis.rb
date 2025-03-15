# typed: false
# frozen_string_literal: true

module Sentiments
  class Analysis
    include BaseService

    use_adapters Adapters::LunarCrush, Adapters::Santiment, Adapters::Senticrypt, Adapters::Twitter
    configure ServicesConfig.sentiment_config

    def call
      if @asset_symbol
        with_caching("sentiment:#{@asset_symbol}") do
          fetch_sentiment_data
        end
      else
        with_caching('top_buzzing_coins') do
          find_top_buzzing_coins
        end
      end
    end

    private

    def fetch_sentiment_data
      fetch_data_with_adapters(:fetch_sentiment)
    end

    def find_top_buzzing_coins
      all_coins_data = {}

      try_adapters_with_config(@adapters, :fetch_buzzing_coins) do |adapter|
        adapter.fetch_buzzing_coins.each do |coin_data|
          symbol = coin_data[:symbol]
          score = coin_data[:score]

          all_coins_data[symbol] ||= 0
          all_coins_data[symbol] += score
        end
      end

      all_coins_data.sort_by { |_, score| -score }.first(20).to_h
    end
  end
end
