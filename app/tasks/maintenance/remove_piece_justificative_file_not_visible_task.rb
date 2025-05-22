# frozen_string_literal: true

module Maintenance
  class RemovePieceJustificativeFileNotVisibleTask < MaintenanceTasks::Task
    attribute :procedure_id, :string
    validates :procedure_id, presence: true

    def collection
      procedure = Procedure.with_discarded.find(procedure_id.strip.to_i)
      procedure.dossiers.state_not_brouillon
    end

    def process(dossier)
      dossier.remove_piece_justificative_file_not_visible!
    end
  end
end
