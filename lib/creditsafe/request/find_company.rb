# frozen_string_literal: true

require 'creditsafe/namespace'

module Creditsafe
  module Request
    class FindCompany
      def initialize(search_criteria)
        check_search_criteria(search_criteria)

        @country_code = search_criteria[:country_code]
        @registration_number = search_criteria[:registration_number]
        @city = search_criteria[:city]
      end

      def message
        search_criteria = {
          "#{Creditsafe::Namespace::DAT}:RegistrationNumber" =>
            registration_number
        }

        unless city.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:Address"] =
            { "#{Creditsafe::Namespace::DAT}:City" => city }
        end

        {
          "#{Creditsafe::Namespace::OPER}:countries" => {
            "#{Creditsafe::Namespace::CRED}:CountryCode" => country_code
          },
          "#{Creditsafe::Namespace::OPER}:searchCriteria" => search_criteria
        }
      end

      private

      attr_reader :country_code, :registration_number, :city

      def check_search_criteria(search_criteria)
        if search_criteria[:country_code].nil?
          raise ArgumentError, "country_code is a required search criteria"
        end

        if search_criteria[:registration_number].nil?
          raise ArgumentError,
                "registration_number is a required search criteria"
        end

        if search_criteria[:city] && search_criteria[:country_code] != 'DE'
          raise ArgumentError, "city is only supported for German searches"
        end
      end
    end
  end
end
