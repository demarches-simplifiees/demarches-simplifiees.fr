# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: format_iban_champ_values'
  task format_iban_champ_values: :environment do
    puts "Running deploy task 'format_iban_champ_values'"

    champs = Champs::IbanChamp.where.not(value: nil)
    progress = ProgressReport.new(champs.count)
    champs.find_each do |champ|
      # format IBAN value
      champ.validate
      champ.update_column(:value, champ.value)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
