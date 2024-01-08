# frozen_string_literal: true

module Maintenance
  class T20250512prepareUnifyFlipperValuesTask < MaintenanceTasks::Task
    # Cette tache duplique en bases les identifiants des entité́s Flipper
    # par ex: (User:123) -> (User:123 User;123)
    # pour les rendre à nouveau compatible avec le format natif de Flipper tout
    # en gardant la compatibilité avec le code existant.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      Flipper::Adapters::ActiveRecord::Gate.all
    end

    def process(flipper_gate)
      if flipper_gate.value != flipper_gate.value.sub(':', ';')
        flipper_gate_dup = flipper_gate.dup
        flipper_gate_dup.update(value: flipper_gate.value.sub(':', ';'))
      end
    end
  end
end
