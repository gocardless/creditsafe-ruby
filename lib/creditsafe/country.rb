# frozen_string_literal: true

module Creditsafe
  module Country
    AUSTRALIA                 = "AU"
    AUSTRIA                   = "AT"
    BELGIUM                   = "BE"
    BULGARIA                  = "BG"
    CANADA                    = "CA"
    CROATIA                   = "HR"
    CZECH_REPUBLIC            = "CZ"
    DENMARK                   = "DK"
    ESTONIA                   = "EE"
    FINLAND                   = "FI"
    FRANCE                    = "FR"
    GERMANY                   = "DE"
    GREAT_BRITAIN             = "GB"
    GREECE                    = "GR"
    HUNGARY                   = "HU"
    ICELAND                   = "IS"
    IRELAND                   = "IE"
    ITALY                     = "IT"
    LATVIA                    = "LV"
    LIECHTENSTEIN             = "LI"
    LITHUANIA                 = "LT"
    LUXEMBOURG                = "LU"
    MALTA                     = "MT"
    MOLDOVA                   = "MD"
    NETHERLANDS               = "NL"
    NEW_ZEALAND               = "NZ"
    NORWAY                    = "NO"
    POLAND                    = "PL"
    PORTUGAL                  = "PT"
    ROMANIA                   = "RO"
    SLOVAKIA                  = "SK"
    SLOVENIA                  = "SI"
    SPAIN                     = "ES"
    SWEDEN                    = "SE"
    SWITZERLAND               = "CH"
    UK                        = "GB"
    UNITED_STATES             = "US"

    VAT_NUMBER_SUPPORTED = [
      GERMANY, FRANCE, CZECH_REPUBLIC, SLOVAKIA, BELGIUM, POLAND, PORTUGAL, SPAIN,
      UNITED_STATES, SLOVENIA, CROATIA, BULGARIA, ROMANIA, LATVIA, ESTONIA, MOLDOVA,
      AUSTRIA, ITALY, HUNGARY, FINLAND, DENMARK, AUSTRALIA, GREECE
    ].freeze
  end
end
