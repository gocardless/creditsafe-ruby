# frozen_string_literal: true

require "creditsafe/errors"

module Creditsafe
  module Messages
    class Message
      attr_reader :code, :message, :error

      def initialize(code: nil, message: nil, error: false)
        raise ArgumentError, "Parameters 'code' and 'message' are mandatory" \
                             unless code && message
        @code = code
        @message = message
        @error = error
      end

      alias error? error

      def error_class
        return unless error?

        case code[1].to_i
        when 1 then Creditsafe::DataError
        when 2 then Creditsafe::AccountError
        when 3 then Creditsafe::RequestError
        when 4 then Creditsafe::ProcessingError
        else Creditsafe::UnknownApiError
        end
      end
    end

    # rubocop:disable Metrics/LineLength
    NO_RESULTS                    = Message.new(code: "010101", message: "No results")
    TOO_MANY_RESULTS              = Message.new(code: "010102", message: "Too many results")
    REPORT_UNAVAILABLE            = Message.new(code: "010103", message: "Report unavailable", error: true)
    REPORT_UNAVAILABLE_LEGAL      = Message.new(code: "010104", message: "Report unavailable due to legal causes", error: true)
    REPORT_UNAVAILABLE_ONLINE     = Message.new(code: "010105", message: "Report unavailable online", error: true)
    LEGAL_NOTICE                  = Message.new(code: "010106", message: "Legal notice")
    INVALID_CREDENTIALS           = Message.new(code: "020101", message: "Invalid credentials", error: true)
    ACCESS_RESTRICTED             = Message.new(code: "020102", message: "Access restricted", error: true)
    ACCESS_LIMITS_NEARING         = Message.new(code: "020103", message: "Access limits nearing")
    REPORTBOX_ALMOST_FULL         = Message.new(code: "020201", message: "Reportbox almost full", error: true)
    REPORTBOX_FULL                = Message.new(code: "020202", message: "Reportbox full", error: true)
    INVALID_REQUEST_XML           = Message.new(code: "030101", message: "Invalid request XML", error: true)
    INVALID_OPERATION_PARAMS      = Message.new(code: "030102", message: "Invalid operation parameters", error: true)
    OPERATION_NOT_SUPPORTED       = Message.new(code: "030103", message: "Operation not supported", error: true)
    INVALID_CUSTOM_DATA_SPECIFIED = Message.new(code: "030104", message: "Invalid custom data specified", error: true)
    CHANGE_NOTIFICATION           = Message.new(code: "030201", message: "Change notification")
    TEMPORARY_SYSTEM_PROBLEM      = Message.new(code: "030202", message: "Temporary system problem", error: true)
    ENDPOINT_SHUTDOWN             = Message.new(code: "030203", message: "Endpoint shutdown", error: true)
    UNEXPECTED_INTERNAL_ERROR     = Message.new(code: "040101", message: "Unexpected internal error", error: true)
    OTHER_ERROR                   = Message.new(code: "040102", message: "Other", error: true)
    DATA_SERVICE_PROBLEMS         = Message.new(code: "040103", message: "Data service access problems", error: true)
    DATA_SERVICE_INVALID_RESPONSE = Message.new(code: "040104", message: "Data service invalid response", error: true)
    # rubocop:enable Metrics/LineLength

    ALL = [
      NO_RESULTS,
      TOO_MANY_RESULTS,
      REPORT_UNAVAILABLE,
      REPORT_UNAVAILABLE_LEGAL,
      REPORT_UNAVAILABLE_ONLINE,
      LEGAL_NOTICE,
      INVALID_CREDENTIALS,
      ACCESS_RESTRICTED,
      ACCESS_LIMITS_NEARING,
      REPORTBOX_ALMOST_FULL,
      REPORTBOX_FULL,
      INVALID_REQUEST_XML,
      INVALID_OPERATION_PARAMS,
      OPERATION_NOT_SUPPORTED,
      INVALID_CUSTOM_DATA_SPECIFIED,
      CHANGE_NOTIFICATION,
      TEMPORARY_SYSTEM_PROBLEM,
      ENDPOINT_SHUTDOWN,
      UNEXPECTED_INTERNAL_ERROR,
      OTHER_ERROR,
      DATA_SERVICE_PROBLEMS,
      DATA_SERVICE_INVALID_RESPONSE,
    ].freeze

    # Creditsafe documentation shows a 6 digit error code, however their API
    # strips the leading 0. To comply with the docs, we pad the API code here to
    # ensure we find the right match
    def self.for_code(code)
      padded_code = code.rjust(6, "0")
      message = ALL.find { |msg| msg.code == padded_code }

      if message.nil?
        message = Message.new(code: code, message: "Unknown error", error: true)
      end

      message
    end
  end
end
