# frozen_string_literal: true

require "securerandom"
require "savon"
require "excon"

require "creditsafe/errors"
require "creditsafe/messages"
require "creditsafe/namespace"

require "creditsafe/request/company_report"
require "creditsafe/request/find_company"

require "active_support/notifications"

module Creditsafe
  class Client
    ENVIRONMENTS = %i(live test).freeze

    def initialize(username: nil, password: nil, savon_opts: {},
                   environment: :live, log_level: :warn)
      raise ArgumentError, "Username must be provided" if username.nil?
      raise ArgumentError, "Password must be provided" if password.nil?

      unless ENVIRONMENTS.include?(environment.to_sym)
        raise ArgumentError, "Environment needs to be one of #{ENVIRONMENTS.join('/')}"
      end

      @environment = environment.to_s
      @log_level = log_level
      @username = username
      @password = password
      @savon_opts = savon_opts
    end

    def find_company(search_criteria = {})
      request = Creditsafe::Request::FindCompany.new(search_criteria)
      response = invoke_soap(:find_companies, request.message)

      companies = response.
        fetch(:find_companies_response).
        fetch(:find_companies_result).
        fetch(:companies)

      companies.nil? ? nil : companies.fetch(:company)
    end

    def company_report(creditsafe_id, custom_data: nil)
      request =
        Creditsafe::Request::CompanyReport.new(creditsafe_id, custom_data)
      response = invoke_soap(:retrieve_company_online_report, request.message)

      response.
        fetch(:retrieve_company_online_report_response).
        fetch(:retrieve_company_online_report_result).
        fetch(:reports).
        fetch(:report)
    end

    def inspect
      "#<#{self.class} @username='#{@username}'>"
    end

    private

    def handle_message_for_response(response)
      [
        *response.xpath("//q1:Message"),
        *response.xpath("//xmlns:Message"),
      ].each do |message|
        api_message = Creditsafe::Messages.
          for_code(message.attributes["Code"].value)

        api_error_message = api_message.message
        api_error_message += " (#{message.text})" unless message.text.blank?

        raise api_message.error_class, api_error_message if api_message.error?
      end
    end

    def invoke_soap(message_type, message)
      started = Time.now
      notification_payload = { request: message }

      response = client.call(message_type, message: message)
      handle_message_for_response(response)
      notification_payload[:response] = response.body
    rescue => raw_error
      processed_error = handle_error(raw_error)
      notification_payload[:error] = processed_error
      raise processed_error
    ensure
      publish("creditsafe.#{message_type}", started, Time.now,
              SecureRandom.hex(10), notification_payload)
    end

    def publish(*args)
      ActiveSupport::Notifications.publish(*args)
    end

    # There's a potential bug in the creditsafe API where they actually return
    # an HTTP 401 if you're unauthorized, hence the sad special case below
    def handle_error(error)
      case error
      when Savon::SOAPFault
        return UnknownApiError.new(error.message)
      when Savon::HTTPError
        if error.to_hash[:code] == 401
          return AccountError.new("Unauthorized: invalid credentials")
        end
        return UnknownApiError.new(error.message)
      when Excon::Errors::Error
        return HttpError.new("Error making HTTP request: #{error.message}")
      end
      error
    end

    def client
      @client ||= build_savon_client
    end

    def auth_header
      auth_value = "Basic " + Base64.encode64("#{@username}:#{@password}").chomp
      { "Authorization" => auth_value }
    end

    def build_savon_client
      options = {
        env_namespace: "soapenv",
        namespace_identifier: Creditsafe::Namespace::OPER,
        namespaces: Creditsafe::Namespace::ALL,
        wsdl: wsdl_path,
        headers: auth_header,
        convert_request_keys_to: :none,
        adapter: :excon,
        log: true,
        log_level: @log_level,
        pretty_print_xml: true,
      }
      Savon.client(options.merge(@savon_opts))
    end

    def wsdl_path
      root_dir = File.join(File.dirname(__FILE__), "..", "..")
      File.join(root_dir, "data", "creditsafe-#{@environment}.xml")
    end
  end
end
