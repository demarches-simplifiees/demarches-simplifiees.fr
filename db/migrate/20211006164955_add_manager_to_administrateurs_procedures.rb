# frozen_string_literal: true

class AddManagerToAdministrateursProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :administrateurs_procedures, :manager, :boolean
  end
end
