# frozen_string_literal: true

class AddIsTemplateToProcedures < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedures, :template, :boolean, default: false, null: false
    end
  end
end
