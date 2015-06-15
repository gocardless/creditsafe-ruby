require 'securerandom'
require 'savon'
require 'excon'

require 'creditsafe/errors'
require 'creditsafe/messages'

module Creditsafe
  class Client
    XMLNS_OPER = 'oper'.freeze
    XMLNS_OPER_VAL = 'http://www.creditsafe.com/globaldata/operations'.freeze

    XMLNS_DAT  = 'dat'.freeze
    XMLNS_DAT_VAL  = 'http://www.creditsafe.com/globaldata/datatypes'.freeze

    XMLNS_CRED = 'cred'.freeze
    XMLNS_CRED_VAL =
      'http://schemas.datacontract.org/2004/07/Creditsafe.GlobalData'.freeze

    def initialize(username: nil, password: nil, savon_opts: {})
      raise ArgumentError, "Username must be provided" if username.nil?
      raise ArgumentError, "Password must be provided" if password.nil?
      @username = username
      @password = password
      @savon_opts = savon_opts
    end

    def find_company(country_code: nil, registration_number: nil)
      response = wrap_soap_errors do
        message = find_company_message(country_code, registration_number)
        client.call(:find_companies, message: message)
      end

      response.
        fetch(:find_companies_response).
        fetch(:find_companies_result).
        fetch(:companies).
        fetch(:company)
    end

    def company_report(creditsafe_id)
      response = wrap_soap_errors do
        message = retrieve_company_report_message(creditsafe_id)
        client.call(:retrieve_company_online_report, message: message)
      end

      response.
        fetch(:retrieve_company_online_report_response).
        fetch(:retrieve_company_online_report_result).
        fetch(:reports).
        fetch(:report)
    end

    private

    def find_company_message(country_code, registration_number)
      {
        "#{XMLNS_OPER}:countries" => {
          "#{XMLNS_CRED}:CountryCode" => country_code
        },
        "#{XMLNS_OPER}:searchCriteria" => {
          "#{XMLNS_DAT}:RegistrationNumber" => registration_number
        }
      }
    end

    def retrieve_company_report_message(company_id)
      {
        "#{XMLNS_OPER}:companyId" => "#{company_id}",
        "#{XMLNS_OPER}:reportType" => 'Full',
        "#{XMLNS_OPER}:language" => "EN"
      }
    end

    def handle_message_for_response(response)
      [
        *response.xpath('//q1:Message'),
        *response.xpath('//xmlns:Message')
      ].each do |message|
        api_message = Creditsafe::Messages.
                      for_code(message.attributes['Code'].value)
        raise ApiError, api_message.message if api_message.error?
      end
    end

    # Takes a proc and rescues any SOAP faults, HTTP errors or Creditsafe errors
    # There's a potential bug in the creditsafe API where they actually return
    # an HTTP 401 if you're unauthorized, hence the sad special case below
    def wrap_soap_errors
      response = yield
      handle_message_for_response(response)
      response.body
    rescue => error
      handle_error(error)
    end

    def handle_error(error)
      raise error
    rescue Savon::SOAPFault => error
      raise ApiError, error.message
    rescue Savon::HTTPError => error
      if error.to_hash[:code] == 401
        raise ApiError, 'Unauthorized: invalid credentials'
      end
      raise ApiError, error.message
    rescue Excon::Errors::Error => err
      raise HttpError, "Error making HTTP request: #{err.message}"
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
        namespace_identifier: "#{XMLNS_OPER}",
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
