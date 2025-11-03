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
      if champ.may_fetch_later?
        champ.fetch_later!(wait: rand(0..max_wait))
      end
    end

    # we spread the fethes every 20 seconds per champ
    def max_wait
      count * 20
    end
  end
end
