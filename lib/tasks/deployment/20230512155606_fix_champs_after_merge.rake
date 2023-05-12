namespace :after_party do
  desc 'Deployment task: fix_champs_after_merge'
  task fix_champs_after_merge: :environment do
    puts "Running deploy task 'fix_champs_after_merge'"

    dossiers = Dossier.where('updated_at > ?', 2.days.ago).pluck(:id, :revision_id)
    champs = Champ.where(dossier_id: dossiers.map(&:first)).pluck(:dossier_id, :type_de_champ_id)
    champs_by_dossier_id = champs.group_by(&:first).transform_values { _1.map(&:second) }
    revisions_by_type_de_champ_id = ProcedureRevisionTypeDeChamp
      .where(type_de_champ_id: champs.map(&:second))
      .pluck(:type_de_champ_id, :revision_id)
      .group_by(&:first).transform_values { _1.map(&:second) }

    bad_dossiers = dossiers.filter do |(id, revision_id)|
      (champs_by_dossier_id[id] || []).any? do |type_de_champ_id|
        revision_ids = revisions_by_type_de_champ_id[type_de_champ_id] || []
        !revision_id.in?(revision_ids)
      end
    end

    Dossier
      .where(id: bad_dossiers.map(&:first))
      .includes(champs: { type_de_champ: :revisions })
      .find_each do |dossier|
        bad_champs = dossier.champs.filter { !dossier.revision_id.in?(_1.type_de_champ.revisions.ids) }
        bad_champs.each do |champ|
          type_de_champ = dossier.revision.types_de_champ.find { _1.stable_id == champ.stable_id }
          puts "Updating champ #{champ.id} on dossier #{dossier.id} from #{champ.type_de_champ_id} to type_de_champ #{type_de_champ.id}"
          champ.update_column(:type_de_champ_id, type_de_champ.id)
        end
      end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
