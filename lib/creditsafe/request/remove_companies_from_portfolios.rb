# frozen_string_literal: true

require 'creditsafe/namespace'

module Creditsafe
  module Request
    class RemoveCompaniesFromPortfolios
      def initialize(portfolio_ids, company_ids)
        @portfolio_ids = portfolio_ids
        @company_ids = company_ids
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
            "#{Creditsafe::Namespace::ARR}:unsignedInt" => @portfolio_ids
          ],
          "#{Creditsafe::Namespace::OPER}:companyIds" => {
            "#{Creditsafe::Namespace::ARR}:string" => @company_ids
          }
        }

        message
      end
    end
  end
end
