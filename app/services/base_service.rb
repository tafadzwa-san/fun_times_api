# typed: false
# frozen_string_literal: true

# BaseService module provides a unified interface for services that work with adapters,
# handle caching, and manage errors. This module combines the functionality previously
# split between DataService and Base::Service.
module BaseService
  # Class methods to be extended
  module ClassMethods
    attr_reader :adapters, :config

    # Set the adapters to be used by this service
    def use_adapters(*adapter_classes)
      @adapters = adapter_classes
    end

    # Set the configuration for this service
    def configure(config = {})
      @config = config
    end
  end

  # Extend class methods when module is included
  def self.included(base)
    base.extend(ClassMethods)

    # Define initializer in the including class
    base.class_eval do
      def initialize(asset_symbol = nil, options = {})
        @asset_symbol = asset_symbol&.upcase
        @options = options
        @config = self.class.config
        @force_refresh = options[:force_refresh] || false
        @adapters = self.class.adapters
      end
    end
  end

  # === Adapter Management ===

  # Try multiple adapters with the given configuration
  # Returns `[results, errors]` containing data and errors for all
  # attempted adapters
  def try_adapters_with_config(adapters, method_name, args = nil)
    results = []
    errors = []

    adapters.map do |adapter_class|
      handle_adapter_errors do
        # Extract adapter-specific config and merge with common config
        adapter_specific_config = @config[:adapters][adapter_class.adapter_name.to_sym] || {}
        common_config = ServicesConfig.common_config
        merged_config = common_config.merge(adapter_specific_config)

        adapter = adapter_class.new(args, merged_config)
        result = adapter.public_send(method_name)
        results << result if result
        adapter
      end
    rescue StandardError => e
      errors << { adapter: adapter_class.name, error: e.message }
      nil
    end

    [results, errors]
  end

  # Handle adapter errors gracefully
  def handle_adapter_errors
    yield
  rescue StandardError => e
    Rails.logger.error("Adapter error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil
  end

  # === Data Fetching ===

  # Fetch data using the configured adapters
  def fetch_data_with_adapters(method_name, args = nil)
    adapter_args = args || @asset_symbol
    results, errors = try_adapters_with_config(@adapters, method_name, adapter_args)

    if results.any?
      results.first
    else
      log_adapter_errors(errors)
      nil
    end
  end

  # Log adapter errors for debugging
  def log_adapter_errors(errors)
    return if errors.empty?

    error_messages = errors.map { |e| "#{e[:adapter]}: #{e[:error]}" }.join(', ')
    Rails.logger.error("All adapters failed for #{@asset_symbol}: #{error_messages}")
  end

  # === Caching ===

  # Fetch data with caching
  # If force_refresh is true, bypass the cache and fetch fresh data
  def with_caching(cache_key_prefix, &)
    cache_key = "#{cache_key_prefix}:#{@asset_symbol}"
    cache_ttl = @config[:cache_ttl] || 60

    Rails.cache.fetch(cache_key, expires_in: cache_ttl, force: @force_refresh, &)
  end

  # === Response Formatting ===

  # Format a successful response
  def success_response(data, message = 'Operation successful')
    { success: true, data: data, message: message }
  end

  # Format a failure response
  def failure_response(message, errors = [])
    { success: false, message: message, errors: errors }
  end
end
