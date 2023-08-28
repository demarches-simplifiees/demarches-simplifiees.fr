module ProcedureChorusConcern
  extend ActiveSupport::Concern

  included do
    def chorusable?
      feature_enabled?(:chorus)
    end
  end
end
