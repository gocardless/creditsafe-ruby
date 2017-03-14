require 'creditsafe/namespace'

module Creditsafe
  module Request
    class SetPortfolioMonitoringRules
      def initialize(portfolio_id, rules)
        @portfolio_id = portfolio_id
        @rules = rules
      end

      def message
        #rules = @rules.map do |rule| 
          #{"#{Creditsafe::Namespace::DAT}:Rule" => 1,
            #:attributes! => {"#{Creditsafe::Namespace::DAT}:Rule" => {:Enabled => "true", :EventCode => rule, :MatchAllConditions => "true"}}}
        #end

        empty_array = []
        @rules.each {|rule| empty_array << {}}

        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioId" => @portfolio_id,
          "#{Creditsafe::Namespace::OPER}:newRules" => { 
          "#{Creditsafe::Namespace::DAT}:Rule" => empty_array,
            :attributes! => {"#{Creditsafe::Namespace::DAT}:Rule" => {:Enabled => "true", :EventCode => @rules, :MatchAllConditions => "true"}}
        }}

        binding.pry

        message
      end
    end
  end
end

#<soapenv:Body>
#<oper:SetMonitoringRules>
#<oper:portfolioId>${Data#PortfolioId}</oper:portfolioId>
#<oper:newRules>
#<dat:Rule Enabled="true" EventCode="${Data#EventCode}" MatchAllConditions="true" xmlns:dat="http://www.creditsafe.com/globaldata/datatypes">
#</dat:Rule>
#</oper:newRules>
#</oper:SetMonitoringRules>
