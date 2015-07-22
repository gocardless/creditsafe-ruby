require 'spec_helper'
require 'creditsafe/messages'

RSpec.describe(Creditsafe::Messages) do
  describe "#for_code" do
    subject(:message) { described_class.for_code(code) }

    context "for a valid code" do
      let(:code) { "020101" }
      its(:code) { is_expected.to eq(code) }
      its(:message) { is_expected.to eq('Invalid credentials') }
    end

    context "for a code without leading zero" do
      let(:code) { "20101" }
      its(:code) { is_expected.to eq("0#{code}") }
      its(:message) { is_expected.to eq('Invalid credentials') }
    end

    context "for an unknown code" do
      let(:code) { "999999" }
      its(:code) { is_expected.to eq(code) }
      its(:message) { is_expected.to eq('Unknown error') }
    end
  end
end
