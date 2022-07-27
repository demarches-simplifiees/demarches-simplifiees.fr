namespace :after_party do
  desc 'Deployment task: cleanup_foreign_keys'
  task cleanup_foreign_keys: :environment do
    puts "Running deploy task 'cleanup_foreign_keys'"

    champs_with_invalid_type_de_champ = Champ.where.not(type_de_champ_id: nil).where.missing(:type_de_champ)
    champs_with_invalid_type_de_champ_count = champs_with_invalid_type_de_champ.count

    if champs_with_invalid_type_de_champ_count > 0
      progress = ProgressReport.new(champs_with_invalid_type_de_champ_count)
      Champ.where.not(type_de_champ_id: nil).in_batches(of: 600_000) do |champs|
        count = champs.where.missing(:type_de_champ).count
        if count > 0
          champs.where.missing(:type_de_champ).destroy_all
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No champs with invalid type_de_champ found"
    end

    champs_with_invalid_dossier = Champ.where.not(dossier_id: nil).where.missing(:dossier)
    champs_with_invalid_dossier_count = champs_with_invalid_dossier.count

    if champs_with_invalid_dossier_count > 0
      progress = ProgressReport.new(champs_with_invalid_dossier_count)
      Champ.where.not(dossier_id: nil).in_batches(of: 600_000) do |champs|
        count = champs.where.missing(:dossier).count
        if count > 0
          champs.where.missing(:dossier).destroy_all
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No champs with invalid dossier found"
    end

    champs_with_invalid_etablissement = Champ.where.not(etablissement_id: nil).where.missing(:etablissement)
    champs_with_invalid_etablissement_count = champs_with_invalid_etablissement.count

    if champs_with_invalid_etablissement_count > 0
      progress = ProgressReport.new(champs_with_invalid_etablissement_count)
      Champ.where.not(etablissement_id: nil).in_batches(of: 10_000) do |champs|
        count = champs.where.missing(:etablissement).count
        if count > 0
          champs.where.missing(:etablissement).update_all(etablissement_id: nil)
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No champs with invalid etablissement found"
    end

    etablissements_with_invalid_dossier = Etablissement.where.not(dossier_id: nil).where.missing(:dossier)
    etablissements_with_invalid_dossier_count = etablissements_with_invalid_dossier.count

    if etablissements_with_invalid_dossier_count > 0
      progress = ProgressReport.new(etablissements_with_invalid_dossier_count)
      Etablissement.where.not(dossier_id: nil).in_batches(of: 10_000) do |etablissements|
        count = etablissements.where.missing(:dossier).count
        if count > 0
          etablissements.where.missing(:dossier).update_all(dossier_id: nil)
          progress.inc(count)
        end
      end
      progress.finish
    else
      puts "No etablissements with invalid dossier found"
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
