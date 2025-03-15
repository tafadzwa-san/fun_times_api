# typed: false
# frozen_string_literal: true

module ServicesConfig
  class << self
    def common_config
      {
        log_level: ENV.fetch('SERVICES_LOG_LEVEL', 'info').upcase,
        timeout: ENV.fetch('API_DEFAULT_TIMEOUT', 30).to_i
      }
    end

    def market_data_config
      {
        cache_ttl: ENV.fetch('MARKET_DATA_CACHE_TTL', 15).to_i,
        adapters: {
          kucoin: {
            base_url: ENV.fetch('KUCOIN_API_URL', 'https://api.kucoin.com/api/v1'),
            timeout: ENV.fetch('KUCOIN_API_TIMEOUT', common_config[:timeout])
          },
          coin_gecko: {
            api_url: ENV.fetch('COINGECKO_API_URL', 'https://api.coingecko.com/api/v3'),
            timeout: ENV.fetch('COINGECKO_API_TIMEOUT', common_config[:timeout])
          },
          binance: {
            base_url: ENV.fetch('BINANCE_API_URL', 'https://api.binance.com'),
            timeout: ENV.fetch('BINANCE_API_TIMEOUT', common_config[:timeout]),
            api_key: ENV.fetch('BINANCE_API_KEY', nil),
            api_secret: ENV.fetch('BINANCE_API_SECRET', nil)
          }
        }
      }
    end

    def sentiment_config
      {
        adapters: {
          lunar_crush: {
            base_url: ENV.fetch('LUNARCRUSH_API_URL', 'https://api.lunarcrush.com/v2'),
            api_key: ENV.fetch('LUNARCRUSH_API_KEY', nil),
            timeout: ENV.fetch('LUNARCRUSH_API_TIMEOUT', common_config[:timeout])
          },
          santiment: {
            base_url: ENV.fetch('SANTIMENT_API_URL', 'https://api.santiment.net/graphql'),
            api_key: ENV.fetch('SANTIMENT_API_KEY', nil),
            timeout: ENV.fetch('SANTIMENT_API_TIMEOUT', common_config[:timeout])
          },
          senticrypt: {
            base_url: ENV.fetch('SENTICRYPT_API_URL', 'https://api.senticrypt.com'),
            api_key: ENV.fetch('SENTICRYPT_API_KEY', nil),
            timeout: ENV.fetch('SENTICRYPT_API_TIMEOUT', common_config[:timeout])
          },
          twitter: {
            base_url: ENV.fetch('TWITTER_API_URL', 'https://api.twitter.com/2/tweets/search/recent'),
            api_key: ENV.fetch('TWITTER_API_KEY', nil),
            timeout: ENV.fetch('TWITTER_API_TIMEOUT', common_config[:timeout])
          }
        }
      }
    end

    def trading_config
      {
        default_exchange: ENV.fetch('DEFAULT_TRADING_EXCHANGE', 'KuCoin'),
        adapters: {
          kucoin: {
            api_url: ENV.fetch('KUCOIN_TRADING_API_URL', 'https://api.kucoin.com'),
            api_key: ENV.fetch('KUCOIN_API_KEY', nil),
            api_secret: ENV.fetch('KUCOIN_API_SECRET', nil),
            timeout: ENV.fetch('KUCOIN_API_TIMEOUT', common_config[:timeout])
          }
        }
      }
    end

    def config_for_adapter(service_type, adapter_name)
      config = send(:"#{service_type}_config")
      adapter_config = config[:adapters][adapter_name.to_sym] || {}
      common_config.merge(adapter_config)
    end
  end
end
