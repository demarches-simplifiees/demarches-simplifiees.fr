# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: move_traitement_process_expired_to_procedure'

  task move_traitement_process_expired_to_procedure: :environment do
    procedures = Procedure.joins(dossiers: :traitements).where(dossiers: { traitements: { process_expired: true, process_expired_migrated: false } })
    progress = ProgressReport.new(procedures.count)

    procedures.group(:id).find_each do |procedure|
      ActiveRecord::Base.transaction do
        puts "update traitements from dossier_ids: #{procedure.dossiers.ids}"
        Traitement.where(id: procedure.dossiers.ids).update_all(process_expired_migrated: true)
        procedure.update(procedure_expires_when_termine_enabled: true)
        progress.inc
      end
    end
    progress.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
