# frozen_string_literal: true

module Maintenance
  class DisableRemainingInvalidMonAvisTask < MaintenanceTasks::Task
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
