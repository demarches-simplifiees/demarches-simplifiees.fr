FactoryBot.define do
  factory :export do
    format { Export.formats.fetch(:csv) }
    statut { Export.statuts.fetch(:tous) }
    time_span_type { Export.time_span_types.fetch(:everything) }
    groupe_instructeurs { [association(:groupe_instructeur)] }

    after(:build) do |export, _evaluator|
      export.key = Export.generate_cache_key(export.groupe_instructeurs.map(&:id), export.procedure_presentation)
      export.user_profile = export.groupe_instructeurs.first&.instructeurs&.first if export.user_profile.nil?
      export.dossiers_count = 10 if !export.pending?
    end
  end
end
