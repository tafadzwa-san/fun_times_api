# typed: false
# frozen_string_literal: true

require 'faraday'
require 'json'
require 'logger'

module Base
  class Adapter
    attr_reader :logger, :config

    def initialize(config = {})
      @base_url = config[:base_url]
      @api_key = config[:api_key]
      @api_secret = config[:api_secret]
      @timeout = config[:timeout] || 30
      @logger = config[:logger] || Logger.new($stdout)
      @logger.level = config[:log_level] || Logger::INFO
      @config = config

      validate_configuration
    end

    protected

    def validate_configuration
      return if @base_url

      raise ArgumentError,
            "No base URL provided for #{self.class.name}. Either define API_URL constant or provide :base_url in config"
    end

    def get(endpoint, params = {})
      request(:get, endpoint, params)
    end

    def post(endpoint, payload = {})
      request(:post, endpoint, {}, payload)
    end

    def put(endpoint, payload = {})
      request(:put, endpoint, {}, payload)
    end

    def delete(endpoint, params = {})
      request(:delete, endpoint, params)
    end

    def request(method, endpoint, params = {}, payload = nil)
      # If endpoint is a full URL, use it directly; otherwise treat as a path
      url = endpoint
      log_request(method, url, params, payload)

      response = connection.public_send(method) do |req|
        req.url url
        req.params = params if params.any?
        req.body = serialize_payload(payload) if payload
        req.options.timeout = @timeout
        set_headers(req)
        apply_authentication(req) if respond_to?(:apply_authentication, true)
      end

      log_response(response)
      handle_response(response)
    rescue Faraday::ConnectionFailed => e
      handle_connection_error(e, 'Connection failed')
    rescue Faraday::TimeoutError => e
      handle_connection_error(e, 'Request timed out')
    rescue StandardError => e
      handle_connection_error(e, 'Request failed')
    end

    def handle_response(response)
      unless response.success?
        raise api_error_class.new("API Error: HTTP #{response.status}", response.status, adapter_name,
                                  response.body)
      end

      parse_json(response.body)
    end

    def parse_json(body)
      return {} if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError => e
      log_error('Invalid JSON', e)
      raise api_error_class.new("Invalid JSON response: #{e.message}", nil, adapter_name, body)
    end

    def connection
      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = @base_url
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def set_headers(request) # rubocop:disable Naming/AccessorMethodName
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
    end

    def serialize_payload(payload)
      payload.is_a?(String) ? payload : payload.to_json
    end

    def adapter_name
      self.class.name.demodulize
    end

    def handle_connection_error(exception, message)
      log_error(message, exception)
      raise api_error_class.new("#{message}: #{exception.message}", nil, adapter_name)
    end

    def log_request(method, url, params, payload = nil)
      @logger.debug("[#{adapter_name}] Request: #{method.upcase} #{url}")
      @logger.debug("[#{adapter_name}] Params: #{params.inspect}") if params.any?
      @logger.debug("[#{adapter_name}] Payload: #{payload.inspect}") if payload
    end

    def log_response(response)
      @logger.debug("[#{adapter_name}] Response status: #{response.status}")
      truncated = response.body.to_s
      truncated = "#{truncated[0..500]}..." if truncated.length > 500
      @logger.debug("[#{adapter_name}] Response body: #{truncated}")
    end

    def log_error(message, exception)
      @logger.error("[#{adapter_name}] #{message}: #{exception.class} - #{exception.message}")
      @logger.debug("[#{adapter_name}] Backtrace: #{exception.backtrace[0..5].join("\n")}")
    end

    def api_error_class
      Errors::ApiError
    end
  end
end
