# frozen_string_literal: true

require 'creditsafe/namespace'
require 'creditsafe/match_type'

module Creditsafe
  module Request
    class FindCompany
      def initialize(search_criteria)
        check_search_criteria(search_criteria)
        @country_code = search_criteria[:country_code]
        @registration_number = search_criteria[:registration_number]
        @company_name = search_criteria[:company_name]
        @city = search_criteria[:city]
        @postal_code = search_criteria[:postal_code]
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def message
        search_criteria = {}

        search_criteria["#{Creditsafe::Namespace::DAT}:Name"] = {
          '@MatchType' => match_type,
          :content! => company_name
        } unless company_name.nil?

        unless registration_number.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:RegistrationNumber"] =
            registration_number
        end

        search_criteria["#{Creditsafe::Namespace::DAT}:Address"] = {
          "#{Creditsafe::Namespace::DAT}:City" => city
        } unless city.nil?

        search_criteria["#{Creditsafe::Namespace::DAT}:Address"] = {
          "#{Creditsafe::Namespace::DAT}:PostalCode" => postal_code
        } unless postal_code.nil?

        build_message(search_criteria)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      private

      attr_reader :country_code, :registration_number, :city, :company_name, :postal_code

      def match_type
        Creditsafe::MatchType::ALLOWED[country_code.upcase.to_sym]&.first ||
          Creditsafe::MatchType::MATCH_BLOCK
      end

      def build_message(search_criteria)
        {
          "#{Creditsafe::Namespace::OPER}:countries" => {
            "#{Creditsafe::Namespace::CRED}:CountryCode" => country_code
          },
          "#{Creditsafe::Namespace::OPER}:searchCriteria" => search_criteria
        }
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def check_search_criteria(search_criteria)
        if search_criteria[:country_code].nil?
          raise ArgumentError, "country_code is a required search criteria"
        end

        unless only_registration_number_or_company_name_provided?(search_criteria)
          raise ArgumentError, "registration_number or company_name (not both) are " \
                               "required search criteria"
        end

        if search_criteria[:city] && search_criteria[:country_code] != 'DE'
          raise ArgumentError, "city is only supported for German searches"
        end

        if search_criteria[:postal_code] && search_criteria[:country_code] != 'DE'
          raise ArgumentError, "Postal code is only supported for German searches"
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def only_registration_number_or_company_name_provided?(search_criteria)
        search_criteria[:registration_number].nil? ^ search_criteria[:company_name].nil?
      end
    end
  end
end
