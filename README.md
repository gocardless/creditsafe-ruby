# creditsafe-ruby

*Build status: [![Circle CI](https://circleci.com/gh/gocardless/creditsafe-ruby.svg?style=svg&circle-token=3f6e9b24fcc6a57abac110c59395b36032f156a5)](https://circleci.com/gh/gocardless/creditsafe-ruby)*

A ruby library for interacting with the
[creditsafe](http://www.creditsafeuk.com/) API.

Currently, it only partially implements the API to support finding companies by
registration number and retrieving company online reports.

# Installation

Install the gem from RubyGems.org by adding the following to your `Gemfile`:

```ruby
gem 'creditsafe', '~> 0.3.1'
```

Just run `bundle install` to install the gem and its dependencies.

# Usage

Initialise the client with your `username` and `password`.

```ruby
client = Creditsafe::Client.new(username: "foo", password: "bar")

# optionally with environment (live is default) and or log level
client = Creditsafe::Client.new(username: "foo", password: "bar", environment: :test, log_level: :debug)
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

In Germany you can also perform a name search. For this you need to provide a country code and a company name.

```ruby
client.find_company(country_code: "DE", company_name: "zalando")
=> [
  {
    "name": "Zalando Logistics Süd SE & Co. KG",
    "type": "NonLtd",
    "status": "Active",
    "address": {
      "street": "Tamara-Danz-Str. 1",
      "city": "Berlin",
      "postal_code": "10243"
    },
    "available_report_types": {
      "available_report_type": [
        "Full",
        "Basic"
      ]
    },
    "available_languages": {
      "available_language": [
        "EN",
        "DE"
      ]
    },
    "@online_reports": "true",
    "@monitoring": "true",
    "@country": "DE",
    "@id": "DE001/1/DE20316785",
    "@safe_number": "DE20316785"
  },
  {
    "name": "Zalando Outlet Store Berlin",
    "type": "NonLtd",
    "status": "Active",
    "address": {
      "street": "Köpenicker Str. 20",
      "city": "Berlin",
      "postal_code": "10997"
    },
    "available_report_types": {
      "available_report_type": [
        "Full",
        "Basic"
      ]
    },
    "available_languages": {
      "available_language": [
        "EN",
        "DE"
      ]
    },
    "@online_reports": "true",
    "@monitoring": "true",
    "@country": "DE",
    "@id": "DE001/1/DE16031795",
    "@safe_number": "DE16031795"
  },
  ...
]
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


---

GoCardless ♥ open source. If you do too, come [join us](https://gocardless.com/jobs#software-engineer).
