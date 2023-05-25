module ProcedureSVASVRConcern
  extend ActiveSupport::Concern

  included do
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
  end
end
