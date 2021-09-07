# frozen_string_literal: true

require "spec_helper"
require "creditsafe/client"
require "timecop"

URL = "https://webservices.creditsafe.com/GlobalData/1.3/"\
      "MainServiceBasic.svc"

RSpec.describe(Creditsafe::Client) do
  notifications = []
  let(:username) { "AzureDiamond" }
  let(:password) { "hunter2" }

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    ActiveSupport::Notifications.subscribe do |*args|
      notifications << ActiveSupport::Notifications::Event.new(*args)
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before { notifications = [] }

  shared_examples_for "sends notifications" do
    let(:time) { Time.local(1990) }

    it "records a SOAP event" do
      Timecop.freeze(time) { method_call }

      expect(notifications).to match(
        [
          have_attributes(
            name: "creditsafe.#{soap_verb}",
            transaction_id: match(/\A.{20}\Z/),
            time: time,
            end: time,
            payload: {
              request: be_truthy,
              response: be_truthy,
            },
          ),
        ],
      )
    end
  end

  shared_examples_for "handles api errors" do
    context "when an error occurs due to invalid credentials" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture("error-invalid-credentials.html"),
          status: 401,
        )
      end

      it "raises an AccountError" do
        expect { method_call }.to raise_error(
          Creditsafe::AccountError, /invalid credentials/
        ) do |error|
          expect(notifications).to match(
            [
              have_attributes(
                name: "creditsafe.#{soap_verb}",
                payload: {
                  request: be_truthy,
                  error: error,
                },
              ),
            ],
          )
        end
      end
    end

    context "when an error occurs due to a fault" do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture("error-fault.xml"))
      end

      it "raises an UnknownApiError" do
        expect { method_call }.to raise_error(Creditsafe::UnknownApiError) do |error|
          expect(notifications).to match(
            [
              have_attributes(
                name: "creditsafe.#{soap_verb}",
                payload: {
                  request: be_truthy,
                  error: error,
                },
              ),
            ],
          )
        end
      end
    end

    context "when a timeout occurs" do
      before { stub_request(:post, URL).to_timeout }

      it "raises a TimeoutError" do
        expect { method_call }.to raise_error(Creditsafe::TimeoutError)
      end
    end

    context "when a bad gateway error occurs" do
      before { stub_request(:post, URL).to_raise(Excon::Errors::BadGateway) }

      it "raises a BadGatewayError" do
        expect { method_call }.to raise_error(Creditsafe::BadGatewayError)
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
    subject { client.inspect }

    let(:client) { described_class.new(username: username, password: password) }

    it { is_expected.to_not include(password) }
  end

  describe "#find_company" do
    subject { -> { method_call } }

    let(:soap_verb) { "find_companies" }
    let(:client) { described_class.new(username: username, password: password) }
    let(:country_code) { "GB" }
    let(:registration_number) { "RN123" }
    let(:city) { nil }
    let(:postal_code) { nil }
    let(:company_name) { nil }
    let(:vat_number) { nil }
    let(:search_criteria) do
      {
        country_code: country_code,
        registration_number: registration_number,
        company_name: company_name,
        vat_number: vat_number,
        city: city,
        postal_code: postal_code,
      }.compact
    end

    let(:find_company) { client.find_company(search_criteria) }
    let(:method_call) { find_company }

    before do
      stub_request(:post, URL).to_return(
        body: load_fixture("find-companies-successful.xml"),
        status: 200,
      )
    end

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

    context "with a company name" do
      let(:country_code) { "FR" }
      let(:registration_number) { nil }
      let(:company_name) { "Mimes Inc" }

      it { is_expected.to_not raise_error }

      it "selects a valid match type for the country code" do
        find_company

        request = a_request(:post, URL).with do |req|
          body = Nokogiri::XML(req.body)
          expect(body.xpath("//dat:Name").first.attributes["MatchType"].value).
            to eq("MatchBeginning")
        end

        expect(request).to have_been_made
      end
    end

    context "with a vat_number" do
      let(:vat_number) { "942404110" }
      let(:registration_number) { nil }

      it { is_expected.to raise_error(ArgumentError) }

      context "in US" do
        let(:country_code) { "US" }

        it { is_expected.to_not raise_error }
      end
    end

    context "with different invalid required criteria combinations used" do
      context "with registration number and company name" do
        let(:company_name) { "Mimes Inc" }

        it { is_expected.to raise_error(ArgumentError) }
      end

      context "with registration number and vat_number" do
        let(:vat_number) { "942404110" }

        it { is_expected.to raise_error(ArgumentError) }
      end

      context "with company name and vat_number" do
        let(:registration_number) { nil }
        let(:company_name) { "Mimes Inc" }
        let(:vat_number) { "942404110" }

        it { is_expected.to raise_error(ArgumentError) }
      end

      context "with all three required criteria" do
        let(:company_name) { "Mimes Inc" }
        let(:vat_number) { "942404110" }

        it { is_expected.to raise_error(ArgumentError) }
      end

      context "with no required criteria" do
        let(:registration_number) { nil }

        it { is_expected.to raise_error(ArgumentError) }
      end
    end

    it "requests the company deatils" do
      find_company
      expect(a_request(:post, URL).with do |req|
               expect(CompareXML.equivalent?(
                        Nokogiri::XML(req.body),
                        load_xml_fixture("find-companies-request.xml"),
                        verbose: true,
                      )).to eq([])
             end).to have_been_made
    end

    it "returns the company details" do
      expect(find_company).
        to eq(:name => "GOCARDLESS LTD",
              :type => "Ltd",
              :status => "Active",
              :registration_number => "07495895",
              :address => {
                simple_value: "338-346, GOSWELL, LONDON",
                postal_code: "EC1V7LQ",
              },
              :available_report_types => { available_report_type: "Full" },
              :available_languages => { available_language: "EN" },
              :@date_of_latest_accounts => "2014-01-31T00:00:00Z",
              :@online_reports => "true",
              :@monitoring => "false",
              :@country => "GB",
              :@id => "GB003/0/07495895")
    end

    include_examples "sends notifications"
    include_examples "handles api errors"

    context "when no companies are found" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture("find-companies-none-found.xml"),
          status: 200,
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
                      "There are no results matching specified criteria.",
                    ),
                  },
                  companies: be_nil,
                ),
              ),
            },
          },
        )])
      end
    end

    context "when an error occurs with further details" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture("find-companies-error.xml"),
          status: 200,
        )
      end

      it "gives a useful error, with the specific error in the response" do
        expect { method_call }.to raise_error(
          Creditsafe::RequestError,
          "Invalid operation parameters (Invalid countries list specified.)",
        )
      end

      context "with further details provided in the response" do
        before do
          stub_request(:post, URL).to_return(
            body: load_fixture("find-companies-error-no-text.xml"),
            status: 200,
          )
        end

        it "gives a useful error, with the specific error in the response" do
          expect { method_call }.to raise_error(
            Creditsafe::RequestError,
            "Invalid operation parameters",
          )
        end
      end
    end
  end

  describe "#company_report" do
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture("company-report-successful.xml"),
        status: 200,
      )
    end

    let(:soap_verb) { "retrieve_company_online_report" }
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    let(:company_report) do
      client.company_report("GB003/0/07495895", custom_data: custom_data)
    end
    let(:method_call) { company_report }

    it "requests the company details" do
      company_report
      request = a_request(:post, URL).with do |req|
        expect(
          CompareXML.equivalent?(
            Nokogiri::XML(req.body),
            load_xml_fixture("company-report-request.xml"),
            verbose: true,
          ),
        ).to eq([])
      end

      expect(request).to have_been_made
    end

    it "returns the company details" do
      expect(company_report).to include(:company_summary)
    end

    include_examples "sends notifications"
    include_examples "handles api errors"

    context "when a report is unavailable" do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture("company-report-not-found.xml"))
      end

      it "raises an error" do
        expect { company_report }.to raise_error(Creditsafe::DataError)
      end

      it "gives a useful error message" do
        expect { company_report }.to raise_error(
          Creditsafe::DataError, /Report unavailable/
        )
      end
    end
  end
end
