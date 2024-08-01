# frozen_string_literal: true

class AddForeignKeyGroupeGestionnaireToAdministrateurs < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :administrateurs, :groupe_gestionnaires, validate: false
  end
end
