FactoryBot.define do
  factory :export do
    format { :csv }
    groupe_instructeurs { [association(:groupe_instructeur)] }

    after(:build) do |export, _evaluator|
      export.key = Export.generate_cache_key(export.groupe_instructeurs)
    end
  end
end
