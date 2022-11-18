# frozen_string_literal: true

require "creditsafe/match_type"
require "creditsafe/namespace"
require "creditsafe/country"

module Creditsafe
  module Request
    class FindCompany
      def initialize(search_criteria)
        check_search_criteria(search_criteria)
        @country_code = search_criteria[:country_code]
        @registration_number = search_criteria[:registration_number]
        @company_name = search_criteria[:company_name]
        @vat_number = search_criteria[:vat_number]
        @city = search_criteria[:city]
        @postal_code = search_criteria[:postal_code]
      end

      def message
        search_criteria = {}

        unless company_name.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:Name"] = {
            "@MatchType" => match_type,
            :content! => company_name,
          }
        end

        unless registration_number.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:RegistrationNumber"] =
            registration_number
        end

        unless vat_number.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:VatNumber"] =
            vat_number
        end

        unless city.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:Address"] = {
            "#{Creditsafe::Namespace::DAT}:City" => city,
          }
        end

        unless postal_code.nil?
          search_criteria["#{Creditsafe::Namespace::DAT}:Address"] = {
            "#{Creditsafe::Namespace::DAT}:PostalCode" => postal_code,
          }
        end

        build_message(search_criteria)
      end
      # rubocop:enable Metrics/MethodLength

      private

      attr_reader :country_code, :registration_number, :city, :company_name, :postal_code,
                  :vat_number

      def match_type
        Creditsafe::MatchType::ALLOWED[country_code.upcase.to_sym]&.first ||
          Creditsafe::MatchType::MATCH_BLOCK
      end

      def build_message(search_criteria)
        {
          "#{Creditsafe::Namespace::OPER}:countries" => {
            "#{Creditsafe::Namespace::CRED}:CountryCode" => country_code,
          },
          "#{Creditsafe::Namespace::OPER}:searchCriteria" => search_criteria,
        }
      end

      def check_search_criteria(search_criteria)
        if search_criteria[:country_code].nil?
          raise ArgumentError, "country_code is a required search criteria"
        end

        unless only_one_required_criteria?(search_criteria)
          raise ArgumentError, "only one of registration_number, company_name or " \
                               "vat number is required search criteria"
        end

        if search_criteria[:city] && search_criteria[:country_code] != "DE"
          raise ArgumentError, "city is only supported for German searches"
        end

        if search_criteria[:postal_code] && search_criteria[:country_code] != "DE"
          raise ArgumentError, "Postal code is only supported for German searches"
        end

        if search_criteria[:vat_number] && !Creditsafe::Country::VAT_NUMBER_SUPPORTED.
            include?(search_criteria[:country_code])
          raise ArgumentError, "VAT number is not supported in this country"
        end
      end

      def only_one_required_criteria?(search_criteria)
        by_registration_number = !search_criteria[:registration_number].nil?
        by_company_name = !search_criteria[:company_name].nil?
        by_vat_number = !search_criteria[:vat_number].nil?

        (by_registration_number ^ by_company_name ^ by_vat_number) &&
          !(by_registration_number && by_company_name && by_vat_number)
      end
    end
  end
end
