# frozen_string_literal: true

class AddHideInstructeurEmailToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :hide_instructeurs_email, :boolean, default: false, null: false
  end
end
