FactoryBot.define do
  factory :export do
    format { :csv }
    time_span_type { Export.time_span_types.fetch(:everything) }
    groupe_instructeurs { [association(:groupe_instructeur)] }

    after(:build) do |export, _evaluator|
      export.key = Export.generate_cache_key(export.groupe_instructeurs.map(&:id))
    end
  end
end
