# frozen_string_literal: true

module Maintenance
  class T20261005RemoveParis2024AccreditationFeatureTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    OBSOLETE_FEATURES = [
      :cojo_type_de_champ,
    ].freeze

    def collection
      OBSOLETE_FEATURES
    end

    def process(feature_key)
      Flipper.remove(feature_key)
    end
  end
end
