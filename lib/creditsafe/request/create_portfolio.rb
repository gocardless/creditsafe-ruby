# frozen_string_literal: true

require "creditsafe/namespace"

module Creditsafe
  module Request
    class CreatePortfolio
      def initialize(information_processing_enabled, name)
        @information_processing_enabled = information_processing_enabled
        @name = name
      end

      # rubocop:disable MethodLength
      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:settings" => {},
          :attributes! => {
            "#{Creditsafe::Namespace::OPER}:settings" =>
            {
              Enabled: @information_processing_enabled.to_s,
              Name: @name,
            },
          },
        }

        message
      end
      # rubocop:enable MethodLength
    end
  end
end
