require 'creditsafe/namespace'

module Creditsafe
  module Request
    class GetPortfolios
      def initialize(portfolio_ids)
        @portfolio_ids = portfolio_ids
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
            "#{Creditsafe::Namespace::ARR}:unsignedInt"=> @portfolio_ids 
          ]
        }

        

        message
      end
    end
  end
end
