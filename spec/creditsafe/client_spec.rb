# frozen_string_literal: true
require 'spec_helper'
require 'creditsafe/client'
require 'timecop'

URL = 'https://webservices.creditsafe.com/GlobalData/1.3/'\
  'MainServiceBasic.svc'

RSpec.describe(Creditsafe::Client) do
  notifications = []
  let(:username) { "AzureDiamond" }
  let(:password) { "hunter2" }
  before(:all) do
    ActiveSupport::Notifications.subscribe do |*args|
      notifications << ActiveSupport::Notifications::Event.new(*args)
    end
  end
  before(:each) { notifications = [] }

  shared_examples_for 'sends notifications' do
    let(:time) { Time.local(1990) }
    it 'records a SOAP event' do
      Timecop.freeze(time) do
        method_call
      end
      expect(notifications).to match([have_attributes(
        name: "creditsafe.#{soap_verb}",
        transaction_id: match(/\A.{20}\Z/),
        time: time,
        end: time,
        payload: {
          request: be_truthy,
          response: be_truthy
        }
      )])
    end
  end
  shared_examples_for 'handles api errors' do
    context 'when an error occurs due to invalid credentials' do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('error-invalid-credentials.html'),
          status: 401
        )
      end

      it 'raises an AccountError' do
        expect { method_call }.to raise_error(
          Creditsafe::AccountError, /invalid credentials/
        ) do |error|
          expect(notifications).to match(
            [
              have_attributes(
                name: "creditsafe.#{soap_verb}",
                payload: {
                  request: be_truthy,
                  error: error
                }
              )
            ]
          )
        end
      end
    end

    context 'when an error occurs due to a fault' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('error-fault.xml'))
      end

      it 'raises an UnknownApiError' do
        expect { method_call }.to raise_error(
          Creditsafe::UnknownApiError
        ) do |error|
          expect(notifications).to match(
            [
              have_attributes(
                name: "creditsafe.#{soap_verb}",
                payload: {
                  request: be_truthy,
                  error: error
                }
              )
            ]
          )
        end
      end
    end

    context 'when a HTTP error occurs' do
      before do
        stub_request(:post, URL).to_timeout
      end

      it 'raises an HttpError' do
        expect { method_call }.to(
          raise_error(Creditsafe::HttpError, /Excon::Error(?:s)?::Timeout/)
        )
      end
    end
  end

  describe "#new" do
    subject do
      -> { described_class.new(username: username, password: password) }
    end

    it { is_expected.to_not raise_error }

    context "without a username" do
      let(:username) { nil }
      it { is_expected.to raise_error(ArgumentError) }
    end
  end

  describe "#inspect" do
    let(:client) { described_class.new(username: username, password: password) }
    subject { client.inspect }

    it { is_expected.to_not include(password) }
  end

  describe '#find_company' do
    let(:soap_verb) { 'find_companies' }
    let(:client) { described_class.new(username: username, password: password) }
    let(:country_code) { "GB" }
    let(:registration_number) { "RN123" }
    let(:city) { nil }
    let(:postal_code) { nil }
    let(:search_criteria) do
      {
        country_code: country_code,
        registration_number: registration_number,
        city: city,
        postal_code: postal_code
      }.reject { |_, v| v.nil? }
    end

    subject(:find_company) { client.find_company(search_criteria) }
    subject(:method_call) { find_company }

    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('find-companies-successful.xml'),
        status: 200
      )
    end

    subject { -> { method_call } }
    it { is_expected.to_not raise_error }

    context "without a country_code" do
      let(:country_code) { nil }
      it { is_expected.to raise_error(ArgumentError) }
    end

    context "without a registration_number" do
      let(:registration_number) { nil }
      it { is_expected.to raise_error(ArgumentError) }
    end

    context "with a city" do
      let(:city) { "Berlin" }
      it { is_expected.to raise_error(ArgumentError) }

      context "in Germany" do
        let(:country_code) { "DE" }
        it { is_expected.to_not raise_error }
      end
    end

    context "with a postal_code" do
      let(:postal_code) { "41199" }
      it { is_expected.to raise_error(ArgumentError) }

      context "in Germany" do
        let(:country_code) { "DE" }
        it { is_expected.to_not raise_error }
      end
    end

    it 'requests the company deatils' do
      find_company
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('find-companies-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the company details' do
      expect(find_company).
        to eq(:name => 'GOCARDLESS LTD',
              :type => 'Ltd',
              :status => 'Active',
              :registration_number => '07495895',
              :address => {
                simple_value: '338-346, GOSWELL, LONDON',
                postal_code: 'EC1V7LQ'
              },
              :available_report_types => { available_report_type: 'Full' },
              :available_languages => { available_language: 'EN' },
              :@date_of_latest_accounts => '2014-01-31T00:00:00Z',
              :@online_reports => 'true',
              :@monitoring => 'false',
              :@country => 'GB',
              :@id => 'GB003/0/07495895')
    end

    include_examples 'sends notifications'
    include_examples 'handles api errors'

    context "when no companies are found" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('find-companies-none-found.xml'),
          status: 200
        )
      end

      it "returns nil" do
        expect(find_company).to be_nil
      end

      it "records a nil payload" do
        find_company
        expect(notifications).to match([have_attributes(
          payload: {
            request: be_truthy,
            response: {
              find_companies_response: include(
                find_companies_result: include(
                  messages: {
                    message: include(
                      "There are no results matching specified criteria."
                    )
                  },
                  companies: be_nil
                )
              )
            }
          }
        )])
      end
    end

    context "when an error occurs with further details" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('find-companies-error.xml'),
          status: 200
        )
      end

      it 'gives a useful error, with the specific error in the response' do
        expect { method_call }.to raise_error(
          Creditsafe::RequestError,
          'Invalid operation parameters (Invalid countries list specified.)'
        )
      end

      context "with further details provided in the response" do
        before do
          stub_request(:post, URL).to_return(
            body: load_fixture('find-companies-error-no-text.xml'),
            status: 200
          )
        end

        it 'gives a useful error, with the specific error in the response' do
          expect { method_call }.to raise_error(
            Creditsafe::RequestError,
            'Invalid operation parameters'
          )
        end
      end
    end
  end

  describe '#company_report' do
    let(:soap_verb) { 'retrieve_company_online_report' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('company-report-successful.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:company_report) do
      client.company_report('GB003/0/07495895', custom_data: custom_data)
    end
    subject(:method_call) { company_report }

    it 'requests the company details' do
      company_report
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('company-report-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the company details' do
      expect(company_report).to include(:company_summary)
    end

    include_examples 'sends notifications'
    include_examples 'handles api errors'

    context 'when a report is unavailable' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('company-report-not-found.xml'))
      end

      it 'raises an error' do
        expect { company_report }.to raise_error(Creditsafe::DataError)
      end

      it 'gives a useful error message' do
        expect { company_report }.to raise_error(
          Creditsafe::DataError, /Report unavailable/
        )
      end
    end
  end

  describe 'get_portfolios' do
    let(:soap_verb) { 'get_portfolios' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('get-portfolios-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:get_portfolios) do
      client.get_portfolios([14_462, 14_461])
    end
    subject(:method_call) { get_portfolios }

    it 'requests the portfolios' do
      get_portfolios
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('get-portfolios-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the portfolio' do
      expect(get_portfolios[0]).to include(:@id => "14460")
    end

    context 'when a portfolio is unavailable' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('get-portfolios-not-found.xml'))
      end

      it 'raises an error' do
        expect { get_portfolios }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { get_portfolios }.to raise_error(
          Creditsafe::RequestError, /Invalid portfolio list/
        )
      end
    end
  end

  describe 'get_portfolio_monitoring_rules' do
    let(:soap_verb) { 'get_monitoring_rules' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('get-monitoring-rules-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:get_portfolio_monitoring_rules) do
      client.get_portfolio_monitoring_rules([14_462])
    end
    subject(:method_call) { get_portfolios_monitoring_rules }

    it 'requests portfolio monitoring rules' do
      get_portfolio_monitoring_rules
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('get-monitoring-rules-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the portfolio rules' do
      expect(get_portfolio_monitoring_rules.first.first).to include(:@event_code)
    end

    context 'when the portfolio_rules are unavailable' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('get-monitoring-rules-not-found.xml'))
      end

      it 'raises an error' do
        expect { get_portfolio_monitoring_rules }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { get_portfolio_monitoring_rules }.to raise_error(
          Creditsafe::RequestError, /Invalid portfolio ID/
        )
      end
    end
  end

  describe 'create_portfolio' do
    let(:soap_verb) { 'create_portfolio' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('create-portfolio-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    subject(:create_portfolio) do
      client.create_portfolio(true, 'development_test')
    end
    subject(:method_call) { create_portfolio }

    it 'requests the portfolios' do
      create_portfolio
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('create-portfolio-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the created portfolio' do
      expect(create_portfolio).to include(:portfolios)
    end
  end

  describe 'remove_portfolios' do
    let(:soap_verb) { 'remove_portfolios' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('remove-portfolios-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:remove_portfolios) do
      client.remove_portfolios([12_421])
    end
    subject(:method_call) { remove_portfolios }

    it 'requests portfolio monitoring rules' do
      remove_portfolios
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('remove-portfolios-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'when the portfolio_rules are unavailable' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('remove-portfolios-not-found.xml'))
      end

      it 'raises an error' do
        expect { remove_portfolios }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { remove_portfolios }.to raise_error(
          Creditsafe::RequestError, /Invalid portfolio list/
        )
      end
    end
  end

  describe 'get_supported_change_events' do
    let(:soap_verb) { 'get_supported_change_events' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('get-supported-change-event-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:get_supported_change_events) do
      client.get_supported_change_events('EN', 'NL')
    end
    subject(:method_call) { get_supported_change_events }

    it 'request supported change events' do
      get_supported_change_events
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('get-supported-change-event-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'language not supported' do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('get-supported-change-event-language-not-found.xml')
        )
      end

      it 'raises an error' do
        expect { get_supported_change_events }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { get_supported_change_events }.to raise_error(
          Creditsafe::RequestError, /language is not supported/
        )
      end
    end
  end

  describe 'set_portfolio_monitoring_rules' do
    let(:soap_verb) { 'set_monitoring_rules' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('set-portfolio-monitoring-rules-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    subject(:set_portfolio_monitoring_rules) do
      client.set_portfolio_monitoring_rules(
        12_422,
        %w(CR PR NC AC DN EC FN UC IC CL HO BN)
      )
    end
    subject(:method_call) { set_monitoring_rules }

    it 'request supported change events' do
      set_portfolio_monitoring_rules
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('set-portfolio-monitoring-rules-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'language not supported' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('set-portfolio-monitoring-rules-not-found.xml'))
      end

      it 'raises an error' do
        expect { set_portfolio_monitoring_rules }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { set_portfolio_monitoring_rules }.to raise_error(
          Creditsafe::RequestError, /Invalid portfolio ID/
        )
      end
    end
  end

  describe 'add_companies_to_portfolios' do
    let(:soap_verb) { 'add_companies_to_portfolios' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('add-companies-to-portfolios-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    subject(:add_companies_to_portfolios) do
      client.add_companies_to_portfolios([12_422], ["NL007/X/629173310000"], ["test1"])
    end
    subject(:method_call) { set_monitoring_rules }

    it 'request supported change events' do
      add_companies_to_portfolios
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('add-companies-to-portfolios-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'company is already being monitored' do
      before do
        stub_request(:post, URL).
          to_return(
            body: load_fixture('add-companies-to-monitoring-already-being-monitored.xml')
          )
      end

      it 'raises an error' do
        expect { add_companies_to_portfolios }.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { add_companies_to_portfolios }.to raise_error(
          Creditsafe::RequestError, /Company is already being monitored/
        )
      end
    end
  end

  describe 'remove_companies_from_portfolios' do
    let(:soap_verb) { 'remove_companies_from_portfolios' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('remove-companies-from-portfolios-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    subject(:remove_companies_from_portfolios) do
      client.remove_companies_from_portfolios([12_422], ["NL007/X/629173310000"])
    end
    subject(:method_call) { remove_companies_from_portfolios }

    it 'request supported change events' do
      remove_companies_from_portfolios
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('remove-companies-from-portfolios-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'company is already removed or invalid id' do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('remove-companies-from-portfolios-invalid-company-id.xml')
        )
      end

      it 'raises an error' do
        expect do
          remove_companies_from_portfolios
        end.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { remove_companies_from_portfolios }.to raise_error(
          Creditsafe::RequestError, /Invalid company ID/
        )
      end
    end
  end

  describe 'list_monitored_companies' do
    let(:soap_verb) { 'list_monitored_companies' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('list-monitored-companies-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    subject(:list_monitored_companies) do
      date_time = DateTime.parse('2017-04-15T10:27:08+02:00')
      client.list_monitored_companies([14_462], 0, 1000, date_time.to_s, "true")
    end
    subject(:method_call) { list_monitored_companies }

    it 'request supported change events' do
      list_monitored_companies
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('list-monitored-companies-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    it 'returns the company details' do
      expect(list_monitored_companies[:result].first).to include(:portfolio)
      expect(list_monitored_companies[:result].first[:portfolio]).to include(:companies)
    end

    context 'no companies are found' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('list-monitored-companies-not-found.xml'))
      end

      it 'not raise an error' do
        expect { list_monitored_companies }.not_to raise_error
      end
    end

    context 'multiple messages without payload' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('list-monitored-companies-multiple-messages.xml'))
      end

      it 'should raise an error' do
        expect { list_monitored_companies }.to raise_error
      end
    end

    context 'multiple messages with payload' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('list-monitored-companies-multiple-messages-with-payload.xml'))
      end

      it 'should not raise an error' do
        expect { list_monitored_companies }.not_to raise_error
      end

      it 'should return the message and result' do
        expect(list_monitored_companies.size).to eq(2)
        expect(list_monitored_companies[:result].nil?).to eq(false)
        expect(list_monitored_companies[:messages].first).to eq('bla')
      end
    end
  end

  describe 'set_default_changes_check_period' do
    let(:soap_verb) { 'set_default_changes_check_period' }
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('set-default-changes-check-period-succes.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    subject(:set_default_changes_check_period) do
      client.set_default_changes_check_period(20)
    end
    subject(:method_call) { set_default_changes_check_period }

    it 'request supported change events' do
      set_default_changes_check_period
      expect(a_request(:post, URL).with do |req|
        expect(CompareXML.equivalent?(
                 Nokogiri::XML(req.body),
                 load_xml_fixture('set-default-changes-check-period-request.xml'),
                 verbose: true
        )).to eq([])
      end).to have_been_made
    end

    context 'no companies are found' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('set-default-changes-check-period-fail.xml'))
      end

      it 'not raise an error' do
        expect do
          set_default_changes_check_period
        end.to raise_error(Creditsafe::RequestError)
      end

      it 'gives a useful error message' do
        expect { set_default_changes_check_period }.to raise_error(
          Creditsafe::RequestError, /The maximal value possible to set is 30 days/
        )
      end
    end
  end
end
