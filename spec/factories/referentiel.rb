# frozen_string_literal: true

FactoryBot.define do
  factory :referentiel do
    factory :csv_referentiel, class: 'Referentiels::CsvReferentiel' do
      name { 'referentiel.csv' }
      headers { ['option', 'calorie (kcal)', 'poids (g)'] }
      trait :with_items do
        after(:create) do |referentiel|
          create(:referentiel_item, referentiel:, data: { 'option' => 'fromage', 'calorie (kcal)' => '145', 'poids (g)' => '60' })
          create(:referentiel_item, referentiel:, data: { 'option' => 'dessert', 'calorie (kcal)' => '170', 'poids (g)' => '70' })
          create(:referentiel_item, referentiel:, data: { 'option' => 'fruit', 'calorie (kcal)' => '100', 'poids (g)' => '50' })
        end
      end
    end

    factory :api_referentiel, class: 'Referentiels::APIReferentiel' do
    end
  end
end
