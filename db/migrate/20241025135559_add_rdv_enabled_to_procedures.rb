# frozen_string_literal: true

class AddRdvEnabledToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :rdv_enabled, :boolean, default: false, null: false
  end
end
