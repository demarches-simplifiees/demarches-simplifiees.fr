# frozen_string_literal: true

class InstructeursProcedure < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure

  def self.update_instructeur_procedures_positions(instructeur, ordered_procedure_ids)
    procedure_id_position = ordered_procedure_ids.reverse.each.with_index.to_h
    InstructeursProcedure.transaction do
      procedure_id_position.each do |procedure_id, position|
        InstructeursProcedure.where(procedure_id:, instructeur:).update(position:)
      end
    end
  end
end
