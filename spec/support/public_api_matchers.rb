# frozen_string_literal: true

RSpec::Matchers.define :have_failed_with do |expected|
  match do |response|
    JSON.parse(response.body).with_indifferent_access.dig(:error) == expected
  end
end
