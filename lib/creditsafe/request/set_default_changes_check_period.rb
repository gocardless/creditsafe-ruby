# frozen_string_literal: true

require "creditsafe/namespace"

module Creditsafe
  module Request
    class SetDefaultChangesCheckPeriod
      def initialize(days)
        @days = days
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:days" => @days,
        }

        message
      end
    end
  end
end
