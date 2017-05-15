# frozen_string_literal: true

require 'creditsafe/namespace'

module Creditsafe
  module Request
    class AddCompaniesToPortfolios
      def initialize(portfolio_ids, company_ids, company_descriptions)
        @portfolio_ids = portfolio_ids
        @company_ids = company_ids
        @company_descriptions = company_descriptions
      end

      # rubocop:disable MethodLength
      def message
        {
          "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
            "#{Creditsafe::Namespace::ARR}:unsignedInt" => @portfolio_ids
          ],
          "#{Creditsafe::Namespace::OPER}:companies" => {
            "#{Creditsafe::Namespace::DAT}:Companies" => {
              "#{Creditsafe::Namespace::DAT}:Company" => @company_descriptions,
              :attributes! => {
                "#{Creditsafe::Namespace::DAT}:Company" => {
                  key: @company_ids
                }
              }
            }
          }
        }
      end
    end
  end
end
