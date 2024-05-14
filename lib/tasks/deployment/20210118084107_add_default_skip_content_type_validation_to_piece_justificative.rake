# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: add_default_skip_content_type_validation_to_piece_justificative'
  task add_default_skip_content_type_validation_to_piece_justificative: :environment do
    puts "Running deploy task 'add_default_skip_content_type_validation_to_piece_justificative'"
    tdcs = TypeDeChamp.where(type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative))
    progress = ProgressReport.new(tdcs.count)
    tdcs.find_each do |tdc|
      tdc.update(skip_content_type_pj_validation: true)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
