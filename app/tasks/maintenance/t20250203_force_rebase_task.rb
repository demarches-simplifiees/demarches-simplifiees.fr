# frozen_string_literal: true

module Maintenance
  class T20250203ForceRebaseTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de forcer le rebase sur une sélection de démarches

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    attribute :demarche_numbers, :string
    validates :demarche_numbers, presence: true

    def collection
      Procedure.where(id: demarche_numbers.split(',').map(&:strip).map(&:to_i))
    end

    def process(procedure)
      procedure.dossiers
        .state_not_termine
        .find_each(&:rebase_later)
    end
  end
end
