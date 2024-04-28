# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: seed_hidden_at_dossiers'
  task seed_hidden_at_dossiers: :environment do
    puts "Running deploy task 'seed_hidden_at_dossiers'"

    Dossier
      .with_discarded
      .where.not(hidden_at: nil)
      .where(hidden_by_user_at: nil, hidden_by_administration_at: nil)
      .update_all('hidden_by_user_at = hidden_at, hidden_by_administration_at = hidden_at')

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
