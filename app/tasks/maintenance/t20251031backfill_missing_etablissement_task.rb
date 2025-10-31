# frozen_string_literal: true

module Maintenance
  class T20251031backfillMissingEtablissementTask < MaintenanceTasks::Task
    # Cette tâche permet de re-fetch les établissements manquants

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    csv_collection

    def process(row)
      champ = Champs::SiretChamp.find_by(id: row["champ_id"].to_i)

      return if champ.nil?
      return if champ.external_id.nil?

      champ.reset_external_data!
      champ.fetch_later! if champ.may_fetch_later?
    end
  end
end
