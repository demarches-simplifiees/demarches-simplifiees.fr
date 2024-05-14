# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_procedure_presentation_with_depose_since'
  task fix_procedure_presentation_with_depose_since: :environment do
    puts "Running deploy task 'fix_procedure_presentation_with_depose_since'"

    # Put your task implementation HERE.
    errored_presentation = {
      'label' => "Déposé depuis",
      'table' => "self",
      'column' => "depose_since",
      'classname' => ""
    }
    procedures_presentations = ProcedurePresentation.where("displayed_fields @> ?", [errored_presentation].to_json)
    progress = ProgressReport.new(procedures_presentations.size)

    procedures_presentations.find_each do |procedure_presentation|
      procedure_presentation.displayed_fields.delete_if do |field|
        ['updated_since', 'depose_since'].include?(field['column'])
      end
      procedure_presentation.save
      progress.inc
    end

    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
