# frozen_string_literal: true

class ValidateAndAddNotNullPositionOnInstructeursProcedures < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :instructeurs_procedures, name: "instructeurs_procedures_position_null"
    change_column_null :instructeurs_procedures, :position, false
    remove_check_constraint :instructeurs_procedures, name: "instructeurs_procedures_position_null"
  end

  def down
    add_check_constraint :instructeurs_procedures, "position IS NOT NULL", name: "instructeurs_procedures_position_null", validate: false
    change_column_null :instructeurs_procedures, :position, true
  end
end
