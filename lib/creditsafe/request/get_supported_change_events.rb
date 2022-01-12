# frozen_string_literal: true

require "creditsafe/namespace"

module Creditsafe
  module Request
    class GetSupportedChangeEvents
      def initialize(language, country)
        @language = language
        @country = country
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:language" => @language,
          "#{Creditsafe::Namespace::OPER}:country" => @country,
        }

        message
      end
    end
  end
end
