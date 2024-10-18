# frozen_string_literal: true

module Maintenance
  class BackfillProcedureLabelsForProceduresTask < MaintenanceTasks::Task
    # Cette tâche permet de créer un jeu de labels génériques pour les anciennes procédures
    # Plus d'informations sur l'implémentation des labels ici : https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/9787
    # 2024-10-15

    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      Procedure
        .includes(:procedure_labels)
        .where(procedure_labels: { id: nil })
    end

    def process(procedure)
      ProcedureLabel::GENERIC_LABELS.each do |label|
        ProcedureLabel.create(name: label[:name], color: label[:color], procedure_id: procedure.id)
      end
    end
  end
end
