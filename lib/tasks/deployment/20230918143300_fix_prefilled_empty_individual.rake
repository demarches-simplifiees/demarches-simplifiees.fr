# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_prefilled_empty_individual'
  task fix_prefilled_empty_individual: :environment do
    puts "Running deploy task 'fix_prefilled_empty_individual'"

    Dossier.prefilled.joins(:procedure).joins(:individual).where(procedure: { for_individual: false }).find_each do |dossier|
      rake_puts "Destroy Individual of dossier ##{dossier.id}"
      dossier.individual.destroy!
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
