# frozen_string_literal: true

class DropUnusedIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :champs, :type_de_champ_id
  end
end
