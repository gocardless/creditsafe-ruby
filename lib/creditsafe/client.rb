# frozen_string_literal: true
require 'securerandom'
require 'savon'
require 'excon'

require 'creditsafe/errors'
require 'creditsafe/messages'

require 'active_support/notifications'

module Creditsafe
  class Client
    XMLNS_OPER = 'oper'
    XMLNS_OPER_VAL = 'http://www.creditsafe.com/globaldata/operations'

    XMLNS_DAT = 'dat'
    XMLNS_DAT_VAL = 'http://www.creditsafe.com/globaldata/datatypes'

    XMLNS_CRED = 'cred'
    XMLNS_CRED_VAL =
      'http://schemas.datacontract.org/2004/07/Creditsafe.GlobalData'

    def initialize(username: nil, password: nil, savon_opts: {})
      raise ArgumentError, "Username must be provided" if username.nil?
      raise ArgumentError, "Password must be provided" if password.nil?

      @username = username
      @password = password
      @savon_opts = savon_opts
    end

    def find_company(search_criteria = {})
      check_search_criteria(search_criteria)

      response = invoke_soap(:find_companies,
                             find_company_message(search_criteria))
      companies = response.
                  fetch(:find_companies_response).
                  fetch(:find_companies_result).
                  fetch(:companies)

      companies.nil? ? nil : companies.fetch(:company)
    end

    def company_report(creditsafe_id, custom_data: nil)
      response = invoke_soap(
        :retrieve_company_online_report,
        retrieve_company_report_message(creditsafe_id, custom_data)
      )

      response.
        fetch(:retrieve_company_online_report_response).
        fetch(:retrieve_company_online_report_result).
        fetch(:reports).
        fetch(:report)
    end

    private

    def check_search_criteria(search_criteria)
      if search_criteria[:country_code].nil?
        raise ArgumentError, "country_code is a required search criteria"
      end

      if search_criteria[:registration_number].nil?
        raise ArgumentError, "registration_number is a required search criteria"
      end

      if search_criteria[:city] && search_criteria[:country_code] != 'DE'
        raise ArgumentError, "city is only supported for German searches"
      end
    end

    def find_company_message(provided_criteria)
      search_criteria = {
        "#{XMLNS_DAT}:RegistrationNumber" =>
          provided_criteria[:registration_number]
      }

      unless provided_criteria[:city].nil?
        search_criteria["#{XMLNS_DAT}:Address"] =
          { "#{XMLNS_DAT}:City" => provided_criteria[:city] }
      end

      {
        "#{XMLNS_OPER}:countries" => {
          "#{XMLNS_CRED}:CountryCode" => provided_criteria[:country_code]
        },
        "#{XMLNS_OPER}:searchCriteria" => search_criteria
      }
    end

    def retrieve_company_report_message(company_id, custom_data)
      message = {
        "#{XMLNS_OPER}:companyId" => company_id.to_s,
        "#{XMLNS_OPER}:reportType" => 'Full',
        "#{XMLNS_OPER}:language" => "EN"
      }

      unless custom_data.nil?
        message["#{XMLNS_OPER}:customData"] = {
          "#{XMLNS_DAT}:Entries" => {
            "#{XMLNS_DAT}:Entry" => custom_data_entries(custom_data)
          }
        }
      end

      message
    end

    def custom_data_entries(custom_data)
      custom_data.map { |key, value| { :@key => key, :content! => value } }
    end

    def handle_message_for_response(response)
      [
        *response.xpath('//q1:Message'),
        *response.xpath('//xmlns:Message')
      ].each do |message|
        api_message = Creditsafe::Messages.
                      for_code(message.attributes['Code'].value)

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
          return AccountError.new('Unauthorized: invalid credentials')
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
      auth_value = 'Basic ' + Base64.encode64("#{@username}:#{@password}").chomp
      { 'Authorization' => auth_value }
    end

    def build_savon_client
      options = {
        env_namespace: 'soapenv',
        namespace_identifier: XMLNS_OPER,
        namespaces: {
          "xmlns:#{XMLNS_OPER}" => XMLNS_OPER_VAL,
          "xmlns:#{XMLNS_DAT}" => XMLNS_DAT_VAL,
          "xmlns:#{XMLNS_CRED}" => XMLNS_CRED_VAL
        },
        wsdl: wsdl_path,
        headers: auth_header,
        convert_request_keys_to: :none,
        adapter: :excon
      }
      Savon.client(options.merge(@savon_opts))
    end

    def wsdl_path
      root_dir = File.join(File.dirname(__FILE__), '..', '..')
      File.join(root_dir, 'data', "creditsafe-live.xml")
    end
  end
end
