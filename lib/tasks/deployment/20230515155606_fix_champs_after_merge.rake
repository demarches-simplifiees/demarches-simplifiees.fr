# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_champs_after_merge'
  task fix_champs_after_merge: :environment do
    puts "Running deploy task 'fix_champs_after_merge'"

    dossiers = Dossier.joins(:procedure)
      .where('dossiers.updated_at > ?', 10.days.ago)
      .where('dossiers.revision_id != procedures.draft_revision_id')
      .pluck(:id, :revision_id)

    dossier_draft_revision_ids = Dossier.joins(:procedure)
      .where('dossiers.revision_id = procedures.draft_revision_id')
      .pluck(:id)

    champs = Champ.where(dossier_id: dossiers.map(&:first)).pluck(:dossier_id, :type_de_champ_id)
    champs_by_dossier_id = champs.group_by(&:first).transform_values { _1.map(&:second).uniq }
    revisions_by_type_de_champ_id = ProcedureRevisionTypeDeChamp
      .where(type_de_champ_id: champs.map(&:second).uniq)
      .pluck(:type_de_champ_id, :revision_id)
      .group_by(&:first).transform_values { _1.map(&:second).uniq }

    bad_dossier_ids = dossiers.filter do |(id, revision_id)|
      (champs_by_dossier_id[id] || []).any? do |type_de_champ_id|
        revision_ids = revisions_by_type_de_champ_id[type_de_champ_id] || []
        !revision_id.in?(revision_ids)
      end
    end.map(&:first)

    bad_champ_ids = []
    TypeDeChamp.type_champs.values.each do |type_champ|
      puts "Checking #{type_champ} champs"
      bad_champ_ids << Champ.joins(:type_de_champ)
        .where("champs.type = ? and types_de_champ.type_champ != ?", "Champs::#{type_champ.classify}Champ", type_champ).pluck(:id)
    end
    dossier_with_bad_champ_ids = Champ.where(id: bad_champ_ids.flatten.uniq).pluck(:dossier_id)

    dossier_to_check_ids = (bad_dossier_ids + dossier_draft_revision_ids + dossier_with_bad_champ_ids).uniq

    puts "Checking #{dossier_to_check_ids.size} dossiers"
    Dossier
      .where(id: dossier_to_check_ids)
      .includes(:procedure, champs: { type_de_champ: :revisions })
      .find_each do |dossier|
        bad_champs = dossier.champs.filter { !dossier.revision_id.in?(_1.type_de_champ.revisions.ids) || _1.type != "Champs::#{_1.type_champ.classify}Champ" }
        if bad_champs.present?
          if dossier.revision_id == dossier.procedure.draft_revision_id
            # puts "Deleting dossier #{dossier.id} on procedure #{dossier.procedure.id} draft revision"
            # dossier.destroy
          else
            bad_champs.each do |champ|
              type_de_champ = dossier.revision.types_de_champ.find { _1.stable_id == champ.stable_id && champ.type == "Champs::#{_1.type_champ.classify}Champ" }
              if type_de_champ.present?
                puts "Updating champ #{champ.id} on procedure #{dossier.procedure.id}, dossier #{dossier.id} type_de_champ_id from #{champ.type_de_champ_id} to #{type_de_champ.id}"
                champ.update_column(:type_de_champ_id, type_de_champ.id)
              elsif champ.type != "Champs::#{champ.type_de_champ.type_champ.classify}Champ"
                puts "Updating champ #{champ.id} on procedure #{dossier.procedure.id}, dossier #{dossier.id} type from #{champ.type} to #{"Champs::#{champ.type_de_champ.type_champ.classify}Champ"}"
                champ.update_column(:type, "Champs::#{champ.type_de_champ.type_champ.classify}Champ")
              elsif dossier.termine?
                puts "Dossier #{dossier.id} on procedure #{dossier.procedure.id} is #{dossier.state}. Deal with champ #{champ.id} #{champ.type_de_champ_id} #{champ.type} later."
              else
                puts "No fix found for champ #{champ.id} on procedure #{dossier.procedure.id}, dossier #{dossier.id} with type_de_champ_id #{champ.type_de_champ_id} #{champ.type}"
              end
            end
          end
        end
      end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
