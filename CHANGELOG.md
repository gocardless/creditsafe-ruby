## v0.5.2, 29 March 2018

- Raise `Creditsafe::TimeoutError` when a request times out

## v0.5.1, 1 March 2018

- Update allowed MatchTypes for some geos to reflect real world tests

## v0.5.0, 27 February 2018

- Automatically chooses a valid MatchType when searching for companies by name

## v0.4.0, 3 April 2017

- Adds support for including a postal code when searching for German companies by name 
(@manojapr)

## v0.3.2, 27 February 2017

- Adds support for using Creditsafe's test environment, specified when instantiating the
client, as well as customising the log level used by the Savon SOAP client
- Adds support for finding companies in Germany by name, as well as company number

## v0.3.1, 6 January 2017

- Suppress password when inspecting client

## v0.3.0, 4 August 2016

- Add instrumentation to SOAP requests

## v0.2.0, 16 March 2016

- Subclass `ApiError` to distinguish between different Creditsafe error types
  (patch by [greysteil](https://github.com/greysteil))


## v0.1.1, 15 February 2016

- Allow `city` parameter in `find_company` for German company lookups
  (patch by [greysteil](https://github.com/greysteil))
