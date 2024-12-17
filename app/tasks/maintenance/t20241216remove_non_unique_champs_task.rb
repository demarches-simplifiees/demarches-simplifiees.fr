# frozen_string_literal: true

module Maintenance
  class T20241216removeNonUniqueChampsTask < MaintenanceTasks::Task
    # Documentation: cette tâche supprime les champs en double dans un dossier

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Dossier.state_not_brouillon.includes(champs: true)
    end

    def process(dossier)
      dossier.champs.filter { _1.row_id.nil? }.group_by(&:public_id).each do |_, champs|
        if champs.size > 1
          champs.sort_by(&:id)[1..].each(&:destroy)
        end
      end
    end
  end
end
