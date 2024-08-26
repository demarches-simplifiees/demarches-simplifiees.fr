# frozen_string_literal: true

module Maintenance
  # On our production environment, the fk between `champs.dossier_id` and `dossiers.id` had not been created
  # this maintenance task cleans up orphaned champ pointing to deleted dossier
  # next step is to validate the recreated fk
  # For our own record, use it with  PG_STATEMENT_TIMEOUT=300000 ....
  class DeleteOrphanedChampsWithMissingDossierTask < MaintenanceTasks::Task
    def collection
      Champ.select(:id, :type).where.missing(:dossier)
    end

    def process(champ)
      champ.reload # in case we need more data on this champ

      case champ.type
      when 'Champs::CarteChamp' then
        champ.geo_areas.delete_all
      when 'Champs::RepetitionChamp' then
        champ.champs.delete_all
      when 'Champs::SiretChamp' then
        etablissement = champ.etablissement
        champ.update(etablissement_id: nil)
        etablissement.delete
      end
      champ.delete
    end

    def count
      # no count, it otherwise it will timeout
    end
  end
end
