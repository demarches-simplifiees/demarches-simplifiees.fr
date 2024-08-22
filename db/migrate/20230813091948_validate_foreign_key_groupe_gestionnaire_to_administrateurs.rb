# frozen_string_literal: true

class ValidateForeignKeyGroupeGestionnaireToAdministrateurs < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :administrateurs, :groupe_gestionnaires
  end
end
