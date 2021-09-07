# frozen_string_literal: true

module Creditsafe
  class Error < StandardError; end

  class HttpError < Error; end

  class ApiError < Error; end

  class TimeoutError < HttpError; end

  class BadGatewayError < HttpError; end

  class DataError < ApiError; end

  class AccountError < ApiError; end

  class RequestError < ApiError; end

  class ProcessingError < ApiError; end

  class UnknownApiError < ApiError; end
end
