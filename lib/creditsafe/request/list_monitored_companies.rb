require 'creditsafe/namespace'

module Creditsafe
  module Request
    class ListMonitoredCompanies
      def initialize(portfolio_ids, first_position, page_size, changed_since, changed_only)
        @portfolio_ids = portfolio_ids
        @first_position = first_position
        @page_size = page_size
        @changed_only = changed_only
        @changed_since = changed_since
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
            "#{Creditsafe::Namespace::ARR}:unsignedInt"=> @portfolio_ids 
          ],
          "#{Creditsafe::Namespace::OPER}:changedOnly" => @changed_only,
          "#{Creditsafe::Namespace::OPER}:changedSince" => @changed_since,
          "#{Creditsafe::Namespace::OPER}:pageSize" => @page_size,
          "#{Creditsafe::Namespace::OPER}:firstPosition" => @first_position,
        }

        message
      end
    end
  end
end

#<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:oper="http://www.creditsafe.com/globaldata/operations">
   #<soapenv:Header/>
   #<soapenv:Body>
      #<oper:ListMonitoredCompanies>
         #<oper:portfolioIds>
            #<unsignedInt xmlns="http://schemas.microsoft.com/2003/10/Serialization/Arrays">${Data#PortfolioId}</unsignedInt>
         #</oper:portfolioIds>
         #<oper:firstPosition>0</oper:firstPosition>
         #<oper:pageSize>10</oper:pageSize>
         #<oper:changedOnly>true</oper:changedOnly>
      #</oper:ListMonitoredCompanies>
   #</soapenv:Body>
#</soapenv:Envelope>
