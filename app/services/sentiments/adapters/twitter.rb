# typed: false
# frozen_string_literal: true

module Sentiments
  module Adapters
    class Twitter < BaseAdapter
      def fetch_sentiment
        response = get('/tweets/search/recent', {
                         query: "#{@symbol} OR ##{@symbol}",
                         max_results: 100
                       })

        raise Errors::TwitterError, 'Sentiment data missing' if response['data'].blank?

        {
          source: adapter_name,
          symbol: @symbol,
          score: calculate_average_sentiment(response['data']),
          timestamp: Time.now.utc,
          additional_data: {
            tweet_count: response['data'].size
          }
        }
      rescue StandardError => e
        raise Errors::TwitterError, e.message
      end

      def fetch_buzzing_coins
        response = get('/tweets/search/recent', {
                         query: '#crypto OR #cryptocurrency',
                         max_results: 100
                       })

        raise Errors::TwitterError, 'Sentiment data missing' if response['data'].blank?

        analyze_tweets(response['data'])
      rescue StandardError => e
        raise Errors::TwitterError, e.message
      end

      protected

      def extract_sentiment_score(data)
        data['sentiment_score'].to_f
      end

      def extract_additional_data(data)
        {
          tweet_count: data['tweet_count']
        }
      end

      def api_error_class
        Errors::TwitterError
      end

      private

      def calculate_average_sentiment(tweets)
        sentiments = tweets.map { |tweet| analyze_sentiment(tweet['text']) }
        sentiments.sum / sentiments.size
      end

      def analyze_tweets(tweets)
        # Group tweets by mentioned coin and calculate sentiment
        coin_sentiments = {}

        tweets.each do |tweet|
          symbol = extract_coin_symbol(tweet['text'])
          next unless symbol

          sentiment = analyze_sentiment(tweet['text'])

          coin_sentiments[symbol] ||= { count: 0, total_sentiment: 0 }
          coin_sentiments[symbol][:count] += 1
          coin_sentiments[symbol][:total_sentiment] += sentiment
        end

        # Convert to the required format
        coin_sentiments.map do |symbol, data|
          {
            symbol: symbol,
            score: data[:total_sentiment] / data[:count]
          }
        end
      end

      def extract_coin_symbol(text)
        text.scan(/\b[A-Z]{2,5}\b/).first
      end

      def analyze_sentiment(text)
        # Simple placeholder sentiment analysis
        positive_words = %w[bullish up gain profit moon lambo]
        negative_words = %w[bearish down loss crash dump]

        text_lower = text.downcase
        positive_count = positive_words.sum { |word| text_lower.scan(word).count }
        negative_count = negative_words.sum { |word| text_lower.scan(word).count }

        total_count = positive_count + negative_count
        return 50 if total_count.zero?

        (positive_count.to_f / total_count * 100).round
      end

      def apply_authentication(request)
        request.headers['Authorization'] = "Bearer #{@api_key}"
      end
    end
  end
end
