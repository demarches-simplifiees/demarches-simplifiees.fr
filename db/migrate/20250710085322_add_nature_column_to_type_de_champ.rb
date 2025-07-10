# frozen_string_literal: true

class AddNatureColumnToTypeDeChamp < ActiveRecord::Migration[7.1]
  def change
    add_column :types_de_champ, :nature, :text
  end
end
