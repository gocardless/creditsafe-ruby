# frozen_string_literal: true
require 'spec_helper'
require 'creditsafe/client'

URL = 'https://webservices.creditsafe.com/GlobalData/1.3/'\
      'MainServiceBasic.svc'

RSpec.describe(Creditsafe::Client) do
  let(:username) { "b" }
  let(:password) { "c" }

  shared_examples_for 'handles api errors' do
    context 'when an error occurs due to invalid credentials' do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('error-invalid-credentials.html'),
          status: 401
        )
      end

      it 'raises an AccountError' do
        expect { method_call }.to raise_error(Creditsafe::AccountError)
      end

      it 'gives a useful error message' do
        begin
          method_call
        rescue Creditsafe::AccountError => err
          expect(err.message).to include 'invalid credentials'
        end
      end
    end

    context 'when an error occurs due to a fault' do
      before do
        stub_request(:post, URL).
          to_return(body: load_fixture('error-fault.xml'))
      end

      it 'raises an UnknownApiError' do
        expect { method_call }.to raise_error(Creditsafe::UnknownApiError)
      end
    end

    context 'when a HTTP error occurs' do
      before do
        stub_request(:post, URL).to_timeout
      end

      it 'raises an HttpError' do
        expect { method_call }.to(
          raise_error(Creditsafe::HttpError)
        )
      end

      it 'gives a useful error message' do
        begin
          method_call
        rescue Creditsafe::HttpError => err
          expect(err.message).to include 'Excon::Errors::Timeout'
        end
      end
    end
  end

  describe "#new" do
    subject do
      -> { described_class.new(username: username, password: password) }
    end
    let(:username) { "foo" }
    let(:password) { "bar" }

    it { is_expected.to_not raise_error }

    context "without a username" do
      let(:username) { nil }
      it { is_expected.to raise_error(ArgumentError) }
    end

    context "without a password" do
      let(:password) { nil }
      it { is_expected.to raise_error(ArgumentError) }
    end
  end

  describe '#find_company' do
    let(:client) { described_class.new(username: username, password: password) }
    let(:country_code) { "GB" }
    let(:registration_number) { "RN123" }
    let(:city) { nil }
    let(:search_criteria) do
      {
        country_code: country_code,
        registration_number: registration_number,
        city: city
      }.reject { |_, v| v.nil? }
    end
    let(:find_company) { client.find_company(search_criteria) }
    let(:method_call) { find_company }
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
    end

    context "when an error occurs with further details" do
      before do
        stub_request(:post, URL).to_return(
          body: load_fixture('find-companies-error.xml'),
          status: 200
        )
      end

      it 'gives a useful error, with the specific error in the response' do
        begin
          method_call
        rescue Creditsafe::RequestError => err
          expect(err.message).to eq 'Invalid operation parameters ' \
                                    '(Invalid countries list specified.)'
        end
      end

      context "with further details provided in the response" do
        before do
          stub_request(:post, URL).to_return(
            body: load_fixture('find-companies-error-no-text.xml'),
            status: 200
          )
        end

        it 'gives a useful error, with the specific error in the response' do
          begin
            method_call
          rescue Creditsafe::RequestError => err
            expect(err.message).to eq 'Invalid operation parameters'
          end
        end
      end
    end
  end

  describe '#company_report' do
    before do
      stub_request(:post, URL).to_return(
        body: load_fixture('company-report-successful.xml'),
        status: 200
      )
    end
    let(:client) { described_class.new(username: username, password: password) }
    let(:custom_data) { { foo: "bar", bar: "baz" } }
    let(:company_report) do
      client.company_report('GB003/0/07495895', custom_data: custom_data)
    end
    let(:method_call) { company_report }

    it 'returns the company details' do
      expect(company_report).to include(:company_summary)
    end

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
        begin
          company_report
        rescue Creditsafe::DataError => err
          expect(err.message).to include 'Report unavailable'
        end
      end
    end
  end
end
