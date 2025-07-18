# frozen_string_literal: true

class AddCheckConstraintOnInstructeursProceduresPosition < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :instructeurs_procedures, "position IS NOT NULL", name: "instructeurs_procedures_position_null", validate: false
  end
end
