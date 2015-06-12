# creditsafe-ruby

*Build status: [![Circle CI](https://circleci.com/gh/gocardless/creditsafe-ruby.svg?style=svg&circle-token=3f6e9b24fcc6a57abac110c59395b36032f156a5)](https://circleci.com/gh/gocardless/creditsafe-ruby)*

A ruby library for interacting with the
[creditsafe](http://www.creditsafeuk.com/) API.

Currently, it only partially implements the API to support finding companies by
registration number and retrieving company online reports.

# Usage

Initialise the client with your `username` and `password`.

```ruby
client = Creditsafe::Client.new(username: "foo", password: "bar")
```

### Company Search

To perform a search for a company, you need to provide a country code and a company registration number.

```ruby
client.find_company(country_code: "GB", registration_number: "07495895")
=> {
    name: "GOCARDLESS LTD",
    type: "Ltd",
    status: "Active",
    registration_number: "07495895",
    address: {
        simple_value: "338-346, GOSWELL, LONDON",
        postal_code: "EC1V7LQ"
    },
    available_report_types: { available_report_type: "Full" },
    available_languages: { available_language: "EN" },
    @date_of_latest_accounts: "2014-01-31T00:00:00Z",
    @online_reports: "true",
    @monitoring: "false",
    @country: "GB",
    @id: "GB003/0/07495895"
   }
```

### Company Report

To download all the information available in an online company report, you will
need the company's creditsafe identifier (obtainable using
[find_company](#find_company) above.

```ruby
client.company_report(creditsafe_id: "GB003/0/07495895")
=> {
    ...
   }
```
