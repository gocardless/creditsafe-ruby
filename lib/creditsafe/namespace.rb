# frozen_string_literal: true

module Creditsafe
  module Namespace
    OPER = "oper"
    OPER_VAL = "http://www.creditsafe.com/globaldata/operations"

    DAT = "dat"
    DAT_VAL = "http://www.creditsafe.com/globaldata/datatypes"

    CRED = "cred"
    CRED_VAL = "http://schemas.datacontract.org/2004/07/Creditsafe.GlobalData"

    ARR = "arr"
    ARR_VAL = "http://schemas.microsoft.com/2003/10/Serialization/Arrays"

    ALL = {
      "xmlns:#{Creditsafe::Namespace::OPER}" => Creditsafe::Namespace::OPER_VAL,
      "xmlns:#{Creditsafe::Namespace::DAT}" => Creditsafe::Namespace::DAT_VAL,
      "xmlns:#{Creditsafe::Namespace::CRED}" => Creditsafe::Namespace::CRED_VAL,
      "xmlns:#{Creditsafe::Namespace::ARR}" => Creditsafe::Namespace::ARR_VAL,
    }.freeze
  end
end
