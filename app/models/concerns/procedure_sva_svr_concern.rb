module ProcedureSVASVRConcern
  extend ActiveSupport::Concern

  included do
    validate :sva_svr_immutable_on_published, if: :will_save_change_to_sva_svr?

    def sva_svr_enabled?
      sva? || svr?
    end

    def sva?
      decision == :sva
    end

    def svr?
      decision == :svr
    end

    def sva_svr_configuration
      @sva_svr_configuration ||= SVASVRConfiguration.new(sva_svr)
    end

    private

    def decision
      sva_svr.fetch("decision", nil)&.to_sym
    end

    def decision_was
      sva_svr_was.fetch("decision", nil)&.to_sym
    end

    def sva_svr_immutable_on_published
      return if brouillon?
      return if [:sva, :svr].exclude?(decision_was)

      errors.add(:sva_svr, :immutable)
    end
  end
end
