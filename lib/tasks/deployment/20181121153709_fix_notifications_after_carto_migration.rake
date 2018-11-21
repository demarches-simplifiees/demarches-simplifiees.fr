require 'rake-progressbar'

namespace :after_party do
  desc 'Deployment task: fix_notifications_after_carto_migration'
  task fix_notifications_after_carto_migration: :environment do
    def fix_notifications(dossier)
      updated_at = dossier.champs[1..-1].map(&:updated_at).max
      champ_carte = dossier.champs.first
      if updated_at && (!champ_carte.updated_at || champ_carte.updated_at > updated_at)
        champ_carte.update_columns(updated_at: updated_at, created_at: updated_at)
      end
    end

    dossiers = Dossier.includes(:champs)
      .joins(procedure: :module_api_carto)
      .where(procedure: { module_api_cartos: { migrated: true } })

    bar = RakeProgressbar.new(dossiers.count)

    dossiers.find_each do |dossier|
      fix_notifications(dossier)
      bar.inc
    end
    bar.finished

    AfterParty::TaskRecord.create version: '20181121153709'
  end
end
