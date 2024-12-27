# frozen_string_literal: true

FactoryBot.define do
  factory :referentiel do
  end

  factory :api_referentiel, class: 'Referentiels::APIReferentiel' do
  end

  trait :configured do
    url { 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/' }
    mode { 'exact_match' }
    test_data { 'PG46YY6YWCX8' }
  end
end
