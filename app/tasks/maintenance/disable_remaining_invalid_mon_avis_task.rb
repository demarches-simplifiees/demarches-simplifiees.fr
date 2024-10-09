# frozen_string_literal: true

module Maintenance
  class DisableRemainingInvalidMonAvisTask < MaintenanceTasks::Task
    # Supprime les codes d’intégration « mon avis » invalides
    # 2024-03-18-01 PR #10120
    def collection
      # rubocop:disable DS/Unscoped
      Procedure.unscoped.where.not(monavis_embed: nil)
      # rubocop:enable DS/Unscoped
    end

    def process(procedure)
      procedure.update_column(:monavis_embed, '') if !procedure.valid? && procedure.errors.key?(:monavis_embed)
    end
  end
end
