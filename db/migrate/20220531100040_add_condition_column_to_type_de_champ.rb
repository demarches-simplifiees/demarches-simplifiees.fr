# frozen_string_literal: true

class AddConditionColumnToTypeDeChamp < ActiveRecord::Migration[6.1]
  def change
    add_column :types_de_champ, :condition, :jsonb
  end
end
