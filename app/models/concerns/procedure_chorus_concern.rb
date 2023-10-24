module ProcedureChorusConcern
  extend ActiveSupport::Concern

  included do
    def chorus_configuration
      @chorus_configuration ||= ChorusConfiguration.new(chorus)
    end

    def chorusable?
      feature_enabled?(:chorus)
    end
  end
end
