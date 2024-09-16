# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_virtual_column_from_procedure_presentation'
  task clean_virtual_column_from_procedure_presentation: :environment do
    ids = ProcedurePresentation.where("jsonb_typeof(displayed_fields) = 'array' AND EXISTS ( select 1 from jsonb_array_elements(displayed_fields) AS element where element ? 'virtual')").ids

    progress = ProgressReport.new(ids.count)

    ProcedurePresentation.where(id: ids).find_each do |procedure_presentation|
      procedure_presentation.displayed_fields = procedure_presentation.displayed_fields.map do |field|
        field.except('virtual')
      end
      procedure_presentation.save!(validate: false)

      progress.inc
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
