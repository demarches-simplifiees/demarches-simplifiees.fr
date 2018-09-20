namespace :'2018_09_20_procedure_presentation_jsonb' do
  task run: :environment do
    ProcedurePresentation.update_all(
      <<~SQL
        displayed_fields = ('[' || ARRAY_TO_STRING(old_displayed_fields, ',') || ']')::JSONB,
        sort = (sort  #>> '{}')::jsonb,
        filters = (filters  #>> '{}')::jsonb
      SQL
    )
  end
end
