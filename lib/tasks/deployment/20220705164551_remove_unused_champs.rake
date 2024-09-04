# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_unused_champs'
  task remove_unused_champs: :environment do
    puts "Running deploy task 'remove_unused_champs'"

    child_champs = Champ.where.not(parent_id: nil).select(:id, :dossier_id, :type_de_champ_id)
    progress = ProgressReport.new(child_champs.size)

    types_de_champ_by_dossier = Hash.new do |hash, dossier_id|
      dossier = Dossier.select(:revision_id).find_by(id: dossier_id)
      if dossier.present?
        hash[dossier_id] = ProcedureRevisionTypeDeChamp.where(revision_id: dossier.revision_id).pluck(:type_de_champ_id)
      else
        hash[dossier_id] = []
      end
    end

    champs_to_destroy = []
    child_champs.find_each do |champ|
      if !types_de_champ_by_dossier[champ.dossier_id].include?(champ.type_de_champ_id)
        champs_to_destroy.push(champ.id)
      end
      progress.inc
    end
    progress.finish

    Champ.where(id: champs_to_destroy).destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
