# frozen_string_literal: true
require 'spec_helper'
require 'creditsafe/messages'

RSpec.describe(Creditsafe::Messages) do
  describe ".for_code" do
    subject(:message) { described_class.for_code(code) }

    context "for a valid code" do
      let(:code) { "020101" }
      its(:code) { is_expected.to eq(code) }
      its(:message) { is_expected.to eq('Invalid credentials') }
      its(:error_class) { is_expected.to eq(Creditsafe::AccountError) }
    end

    context "for a code without leading zero" do
      let(:code) { "20101" }
      its(:code) { is_expected.to eq("0#{code}") }
      its(:message) { is_expected.to eq('Invalid credentials') }
      its(:error_class) { is_expected.to eq(Creditsafe::AccountError) }
    end

    context "for an unknown code" do
      let(:code) { "999999" }
      its(:code) { is_expected.to eq(code) }
      its(:message) { is_expected.to eq('Unknown error') }
      its(:error_class) { is_expected.to eq(Creditsafe::UnknownApiError) }
    end

    context "for an empty code" do
      let(:code) { '' }
      it "was passed the wrong parameters" do
        expect { subject(:message) }.to raise_error
      end
    end
  end

  describe(Creditsafe::Messages::Message) do
    subject(:message) do
      described_class.new(code: code, message: text, error: error)
    end
    let(:text) { "Error message" }
    let(:code) { "020101" }
    let(:error) { true }

    describe "#error_class" do
      subject { message.error_class }

      context "when there is no error" do
        let(:error) { false }
        it { is_expected.to be_nil }
      end

      context "when there is an error" do
        let(:error) { true }

        context "for a processing error code" do
          let(:code) { "040102" }
          it { is_expected.to eq(Creditsafe::ProcessingError) }
        end

        context "for an unknown error code" do
          let(:code) { "060102" }
          it { is_expected.to eq(Creditsafe::UnknownApiError) }
        end
      end
    end
  end
end
