

require 'creditsafe/namespace'

module Creditsafe
  module Request
    class GetPortfolios
      def initialize(portfolio_ids)
        binding.pry
        @portfolio_ids = portfolio_ids
      end

      def message
          message = {
            "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
              { "#{Creditsafe::Namespace::OPER}:unsignedInt" => @portfolio_ids }
            ]
          }

        binding.pry

        message
      end
    end
  end
end
