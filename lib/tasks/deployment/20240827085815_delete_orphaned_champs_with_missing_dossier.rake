# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: delete_orphaned_champs_with_missing_dossier'
  task delete_orphaned_champs_with_missing_dossier: :environment do
    puts "Running deploy task 'delete_orphaned_champs_with_missing_dossier'"

    Champ.select(:id, :type).where.missing(:dossier).each do |champ|
      begin
        champ.reload
        champ.champs.destroy_all if champ.type == 'Champs::RepetitionChamp'
        champ.destroy
        rake_puts "succeed with: #{champ.id}"
      rescue ActiveRecord::RecordNotFound
        rake_puts "failed with: #{champ.id}"
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
