# frozen_string_literal: true

module ProcedureChorusConcern
  extend ActiveSupport::Concern

  included do
    def chorus_configuration
      @chorus_configuration ||= ChorusConfiguration.new(chorus)
    end

    def chorusable?
      feature_enabled?(:engagement_juridique_type_de_champ)
    end
  end
end
