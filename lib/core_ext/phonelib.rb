# frozen_string_literal: true

# Class extensions to the Phonelib module, which allow parsing using several countries at once.
module Phonelib
  # Variation of `.valid_for_country`, that can check several countries at once.
  def self.valid_for_countries?(value, countries)
    countries.any? { |country| valid_for_country?(value, country) }
  end

  # Variation of `Phonelib.parse`, which parses the given string using the first country
  # for which the phone number is valid.
  def self.parse_for_countries(value, passed_countries = [])
    valid_country = passed_countries.find { |country| valid_for_country?(value, country) }
    parse(value, valid_country)
  end
end
