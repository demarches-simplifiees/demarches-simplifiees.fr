# frozen_string_literal: true

module Maintenance
  class BackfillClonedChampsPrivatePieceJustificativesTask < MaintenanceTasks::Task
    def collection
      Dossier.en_brouillon.where.not(parent_dossier_id: nil)
    end

    def process(cloned_dossier)
      cloned_dossier.champs_private
        .filter { checkable_pj?(_1, cloned_dossier) }
        .map do |cloned_champ|
          parent_champ = cloned_dossier.parent_dossier
            .champs_private
            .find { _1.stable_id == cloned_champ.stable_id }

          next if !parent_champ

          parent_blob_ids = parent_champ.piece_justificative_file.map(&:blob_id)
          cloned_blob_ids = cloned_champ.piece_justificative_file.map(&:blob_id)

          if parent_blob_ids.sort == cloned_blob_ids.sort
            cloned_champ.piece_justificative_file.detach
          end
        end
    end

    def checkable_pj?(champ, dossier)
      return false if champ.type != "Champs::PieceJustificativeChamp"
      return false if !champ.piece_justificative_file.attached?
      true
    end
  end
end
