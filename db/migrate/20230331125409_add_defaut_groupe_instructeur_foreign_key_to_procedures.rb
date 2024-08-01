# frozen_string_literal: true

class AddDefautGroupeInstructeurForeignKeyToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :procedures, :groupe_instructeurs, column: :defaut_groupe_instructeur_id, validate: false
  end
end
