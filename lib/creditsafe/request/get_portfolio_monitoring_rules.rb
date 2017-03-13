require 'creditsafe/namespace'

module Creditsafe
  module Request
    class GetPortfolioMonitoringRules
      def initialize(portfolio_id)
        @portfolio_id = portfolio_id
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioId" => @portfolio_id
        }

        message
      end
    end
  end
end
