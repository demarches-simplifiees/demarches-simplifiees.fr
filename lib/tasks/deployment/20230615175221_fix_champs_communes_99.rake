# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_champs_communes_99'
  task fix_champs_communes_99: :environment do
    puts "Running deploy task 'fix_champs_communes_99'"

    champ_ids = Champs::CommuneChamp.where("value_json->>'code_departement' = ?", '99').ids
    Migrations::NormalizeCommunesJob.perform_later(champ_ids)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
