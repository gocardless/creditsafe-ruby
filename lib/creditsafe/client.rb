# frozen_string_literal: true

require "securerandom"
require "savon"
require "excon"

require "creditsafe/errors"
require "creditsafe/messages"
require "creditsafe/namespace"
require 'creditsafe/request/company_report'
require 'creditsafe/request/find_company'
require 'creditsafe/request/get_portfolios'
require 'creditsafe/request/create_portfolio'
require 'creditsafe/request/get_portfolio_monitoring_rules'
require 'creditsafe/request/get_supported_change_events'
require 'creditsafe/request/set_portfolio_monitoring_rules'
require 'creditsafe/request/add_companies_to_portfolios'
require 'creditsafe/request/remove_companies_from_portfolios'
require 'creditsafe/request/list_monitored_companies'
require 'creditsafe/request/set_default_changes_check_period'

require "creditsafe/request/company_report"
require "creditsafe/request/find_company"

require "active_support/notifications"

module Creditsafe
  class Client
    ENVIRONMENTS = %i[live test].freeze

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

    def get_portfolios(portfolio_ids)
      request = Creditsafe::Request::GetPortfolios.new(portfolio_ids)
      response = invoke_soap(:get_portfolios, request.message)

      portfolios = response.
        fetch(:get_portfolios_response).
        fetch(:get_portfolios_result).
        fetch(:portfolios)

        portfolios.nil? ? nil : portfolios.fetch(:portfolio)
    end

    def get_portfolio_monitoring_rules(portfolio_id)
      request = Creditsafe::Request::GetPortfolioMonitoringRules.new(portfolio_id)
      response = invoke_soap(:get_monitoring_rules, request.message)


      result = response.
        fetch(:get_monitoring_rules_response).
        fetch(:get_monitoring_rules_result)

       messages = result.fetch(:messages).nil? ? [] : portfolios.fetch(:message)
       rules = result.fetch(:rules).nil? ? [] : portfolios.fetch(:rule)

       result = [rules, messages]
    end

    def remove_portfolios(portfolio_ids)
      request = Creditsafe::Request::GetPortfolios.new(portfolio_ids)
      invoke_soap(:remove_portfolios, request.message)
    end

    def create_portfolio(information_processing_enabled, name)
      request = Creditsafe::Request::CreatePortfolio.new(information_processing_enabled, name)
      invoke_soap(:create_portfolio, request.message)
    end

    def get_portfolio_monitoring_rules(portfolio_id)
      request = Creditsafe::Request::GetPortfolioMonitoringRules.new(portfolio_id)
      response = invoke_soap(:get_monitoring_rules, request.message)


      result = response.
        fetch(:get_monitoring_rules_response).
        fetch(:get_monitoring_rules_result)

       messages = result.fetch(:messages).nil? ? [] : result.fetch(:message)
       rules = result.fetch(:rules).nil? ? [] : result.fetch(:rules).fetch(:rule)

       result = [rules, messages]
    end

    def remove_portfolios(portfolio_ids)
      request = Creditsafe::Request::GetPortfolios.new(portfolio_ids)
      invoke_soap(:remove_portfolios, request.message)
    end

    def create_portfolio(information_processing_enabled, name)
      request = Creditsafe::Request::CreatePortfolio.new(information_processing_enabled, name)
      response = invoke_soap(:create_portfolio, request.message)

      result = response.
        fetch(:create_portfolio_response).
        fetch(:create_portfolio_result)

      result
    end

    def get_supported_change_events(language, country)
      request = Creditsafe::Request::GetSupportedChangeEvents.new(language, country)
      invoke_soap(:get_supported_change_events, request.message)
    end

    def set_portfolio_monitoring_rules(portfolio_id, rules)
      request = Creditsafe::Request::SetPortfolioMonitoringRules.new(portfolio_id, rules)
      invoke_soap(:set_monitoring_rules, request.message)
    end

    def add_companies_to_portfolios(portfolio_ids, company_ids, company_descriptions)
      request = Creditsafe::Request::AddCompaniesToPortfolios.new(portfolio_ids, company_ids, company_descriptions)
      invoke_soap(:add_companies_to_portfolios, request.message)
    end

    def remove_companies_from_portfolios(portfolio_ids, company_ids)
      request = Creditsafe::Request::RemoveCompaniesFromPortfolios.new(portfolio_ids, company_ids)
      invoke_soap(:remove_companies_from_portfolios, request.message)
    end

    def list_monitored_companies(portfolio_ids, first_position, page_size, changed_since, changed_only)
      request = Creditsafe::Request::ListMonitoredCompanies.new(portfolio_ids, first_position, page_size, changed_since, changed_only)
      response = invoke_soap(:list_monitored_companies, request.message)

      result = response.
        fetch(:list_monitored_companies_response).
        fetch(:list_monitored_companies_result)

      begin
        result = result.fetch(:portfolios)
      rescue
        message =  result.fetch(:messages).fetch(:message)

        if message == 'There are no results matching specified criteria.'
          result = message
        else
          raise '' + message
        end
      end

      result
    end

    def set_default_changes_check_period(days)
      request = Creditsafe::Request::SetDefaultChangesCheckPeriod.new(days)
      invoke_soap(:set_default_changes_check_period, request.message)
    end

    def add_companies_to_portfolios(portfolio_ids, company_ids, company_descriptions)
      request = Creditsafe::Request::AddCompaniesToPortfolios.new(portfolio_ids, company_ids, company_descriptions)
      invoke_soap(:add_companies_to_portfolios, request.message)
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
          for_code(message.attributes['Code'].value)

        api_error_message = api_message.message
        api_error_message += " (#{message.text})" unless message.text.blank?

        raise api_message.error_class, api_error_message if api_message.error?
      end
    end

    # rubocop:disable Style/RescueStandardError
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def invoke_soap(message_type, message)
      started = Time.now
      notification_payload = { request: message }

      response = client.call(message_type, message: message)
      handle_message_for_response(response)
      notification_payload[:response] = response.body
    rescue Excon::Errors::Timeout => raw_error
      notification_payload[:error] = handle_error(raw_error)
      raise TimeoutError
    rescue Excon::Errors::BadGateway => raw_error
      notification_payload[:error] = handle_error(raw_error)
      raise BadGatewayError
    rescue => raw_error
      processed_error = handle_error(raw_error)
      notification_payload[:error] = processed_error
      raise processed_error
    ensure
      publish("creditsafe.#{message_type}", started, Time.now,
              SecureRandom.hex(10), notification_payload)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Style/RescueStandardError

    def publish(*args)
      ActiveSupport::Notifications.publish(*args)
    end

    # There's a potential bug in the creditsafe API where they actually return
    # an HTTP 401 if you're unauthorized, hence the sad special case below
    #
    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

    def client
      @client ||= build_savon_client
    end

    def auth_header
      auth_value = "Basic " + Base64.encode64("#{@username}:#{@password}").chomp
      { "Authorization" => auth_value }
    end

    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

    def wsdl_path
      root_dir = File.join(File.dirname(__FILE__), "..", "..")
      File.join(root_dir, "data", "creditsafe-#{@environment}.xml")
    end
  end
end
