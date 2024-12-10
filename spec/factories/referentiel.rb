# frozen_string_literal: true

FactoryBot.define do
  factory :referentiel do
    factory :csv_referentiel, class: 'Referentiels::CSVReferentiel' do
      name { 'referentiel.csv' }
    end

    factory :api_referentiel, class: 'Referentiels::APIReferentiel' do
    end
  end
end
