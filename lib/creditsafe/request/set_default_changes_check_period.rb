require 'creditsafe/namespace'

module Creditsafe
  module Request
    class SetDefaultChangesCheckPeriod
      def initialize(days)
        @days = days
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:days" => @days,
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
