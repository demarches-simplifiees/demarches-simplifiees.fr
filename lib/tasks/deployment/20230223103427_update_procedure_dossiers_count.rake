# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_procedure_dossiers_count'
  task update_procedure_dossiers_count: :environment do
    puts "Running deploy task 'update_procedure_dossiers_count'"
    progress = ProgressReport.new(Procedure.count)

    Procedure.find_each do |p|
      progress.inc
      begin
        p.update_columns(estimated_dossiers_count: p.dossiers.visible_by_administration.count, dossiers_count_computed_at: Time.zone.now)
      rescue => e
        Sentry.capture_exception(e, extra: { procedure_id: p.id })
      end
    end
    progress.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
