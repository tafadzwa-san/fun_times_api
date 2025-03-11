# typed: false
# frozen_string_literal: true

module Errors
  class ApiError < StandardError
    attr_reader :source, :status_code, :raw_response

    def initialize(message = 'API Error', status_code = nil, source = nil, raw_response = nil) # rubocop:disable Metrics/ParameterLists
      @status_code = status_code
      @source = source || 'API'
      @raw_response = raw_response
      super(message)
    end

    def to_h
      {
        error: true,
        source: source,
        message: message,
        status_code: status_code
      }.compact
    end

    def full_message
      "#{source} Error: #{message}"
    end
  end
end
