# frozen_string_literal: true

class ValidateAddDefautGroupeInstructeurForeignKeyToProcedures < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :procedures, :groupe_instructeurs
  end
end
