# frozen_string_literal: true

FactoryBot.define do
  factory :export_template do
    name { "Mon export" }
    groupe_instructeur
    initialize_with { ExportTemplate.default(name:, groupe_instructeur: groupe_instructeur) }

    trait :enabled_pjs do
      after(:build) do |export_template, _evaluator|
        export_template.pjs.each { _1.instance_variable_set('@enabled', true) }
      end
    end
  end
end
