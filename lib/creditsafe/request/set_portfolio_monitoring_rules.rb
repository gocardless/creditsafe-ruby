
require 'creditsafe/namespace'

module Creditsafe
  module Request
    class SetPortfolioMonitoringRules
      def initialize(portfolio_id, rules)
        @portfolio_id = portfolio_id
        @rules = rules
      end

      def message
        empty_array = []
        @rules.each {|rule| empty_array << {}}

        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioId" => @portfolio_id,
          "#{Creditsafe::Namespace::OPER}:newRules" => {
          "#{Creditsafe::Namespace::DAT}:Rule" => empty_array,
            :attributes! => {"#{Creditsafe::Namespace::DAT}:Rule" => {:Enabled => "true", :EventCode => @rules, :MatchAllConditions => "true"}}
        }}

        message
      end
    end
  end
end
