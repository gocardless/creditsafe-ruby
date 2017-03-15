
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
            "#{Creditsafe::Namespace::ARR}:unsignedInt"=> @portfolio_ids 
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

#<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:oper="http://www.creditsafe.com/globaldata/operations">
   #<soapenv:Header/>
   #<soapenv:Body>
      #<oper:RemoveCompaniesFromPortfolios>
         #<oper:portfolioIds>
            #<arr:unsignedInt xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays">${Data#PortfolioId}</arr:unsignedInt>
         #</oper:portfolioIds>
         #<oper:companyIds>
            #<arr:string xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays">${Data#CompanyId}</arr:string>
         #</oper:companyIds>
      #</oper:RemoveCompaniesFromPortfolios>
   #</soapenv:Body>
#</soapenv:Envelope>
