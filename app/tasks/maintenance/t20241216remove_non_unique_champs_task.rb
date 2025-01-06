# frozen_string_literal: true

module Maintenance
  class T20241216removeNonUniqueChampsTask < MaintenanceTasks::Task
    # Documentation: cette tâche supprime les champs en double dans un dossier

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.includes(champs: true)
    end

    def process(dossier)
      dossier.tmp_fix_uniq_row_ids
    end
  end
end
