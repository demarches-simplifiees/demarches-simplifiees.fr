# frozen_string_literal: true

class RemoveDefaultFromPositionInInstructeursProcedures < ActiveRecord::Migration[7.1]
  def change
    change_column_default :instructeurs_procedures, :position, from: 99, to: nil
  end
end
