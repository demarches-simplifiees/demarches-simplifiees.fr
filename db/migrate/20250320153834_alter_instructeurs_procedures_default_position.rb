# frozen_string_literal: true

class AlterInstructeursProceduresDefaultPosition < ActiveRecord::Migration[7.0]
  def change
    change_column_default :instructeurs_procedures, :position, 99
  end
end
