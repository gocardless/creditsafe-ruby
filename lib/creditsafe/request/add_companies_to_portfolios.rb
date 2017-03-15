require 'creditsafe/namespace'

module Creditsafe
  module Request
    class AddCompaniesToPortfolios
      def initialize(portfolio_ids, company_ids, company_descriptions)
        @portfolio_ids = portfolio_ids
        @company_ids = company_ids
        @company_descriptions = company_descriptions
      end

      def message
        message = {
          "#{Creditsafe::Namespace::OPER}:portfolioIds" => [
            "#{Creditsafe::Namespace::ARR}:unsignedInt"=> @portfolio_ids 
          ],
          "#{Creditsafe::Namespace::OPER}:companies" => {
            "#{Creditsafe::Namespace::DAT}:Companies" => {
              "#{Creditsafe::Namespace::DAT}:Company" => @company_descriptions,
              :attributes! => {"#{Creditsafe::Namespace::DAT}:Company" => {:key => @company_ids}}
            }
          }
        }

        message
      end
    end
  end
end

#<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:oper="http://www.creditsafe.com/globaldata/operations" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:dat="http://www.creditsafe.com/globaldata/datatypes">
#<soapenv:Header/>
#<soapenv:Body>
#<oper:AddCompaniesToPortfolios>
#<oper:portfolioIds>
#<arr:unsignedInt>${Data#PortfolioId}</arr:unsignedInt>
#</oper:portfolioIds>
#<!--Optional:-->
#<oper:company_ids>
#<dat:Companies>
#<dat:Company key="${Data#CompanyId}">soapUI</dat:Company>
#</dat:Companies>
#</oper:company_ids>
#</oper:AddCompaniesToPortfolios>
#</soapenv:Body>
#</soapenv:Envelope>
