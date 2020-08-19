require Rails.root.join("lib", "tasks", "task_helper")

namespace :tmp_set_dossiers_last_updated_at do
  desc 'set for all dossiers last_updated_at'
  task run: :environment do
    start_id = ENV.fetch('DOSSIER_START_AT', 0)

    all_dossiers = Dossier.with_discarded
      .where('dossiers.id > ?', start_id)
      .includes(:champs, :avis, :commentaires)
      .order(:id)

    progress = ProgressReport.new(all_dossiers.count)

    all_dossiers.in_batches do |dossiers|
      dossiers.each do |dossier|
        last_commentaire_updated_at = dossier.commentaires
          .where.not(email: OLD_CONTACT_EMAIL)
          .where.not(email: CONTACT_EMAIL)
          .maximum(:updated_at)
        last_avis_updated_at = dossier.avis.maximum(:updated_at)
        last_champ_updated_at = dossier.champs.maximum(:updated_at)
        last_champ_private_updated_at = dossier.champs_private.maximum(:updated_at)
        dossier.update_columns(
          last_commentaire_updated_at: last_commentaire_updated_at,
          last_avis_updated_at: last_avis_updated_at,
          last_champ_updated_at: last_champ_updated_at,
          last_champ_private_updated_at: last_champ_private_updated_at
        )
        progress.inc
      end
      rake_puts "dossiers lastid: #{dossiers.last.id}"
    end

    progress.finish
  end
end
