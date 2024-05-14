# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: normalize_communes'
  task normalize_communes: :environment do
    puts "Running deploy task 'normalize_communes'"

    champs = Champs::CommuneChamp.where.not(external_id: nil)
    progress = ProgressReport.new(champs.count)

    champs.pluck(:id).in_groups_of(10_000, false) do |champ_ids|
      Migrations::NormalizeCommunesJob.perform_later(champ_ids)
      progress.inc(champ_ids.count)
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
