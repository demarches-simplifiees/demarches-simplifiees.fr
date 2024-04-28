# frozen_string_literal: true

class RemoveIndexDossiersOnHiddenAt < ActiveRecord::Migration[7.0]
  def change
    remove_index :dossiers, name: "index_dossiers_on_hidden_at"
  end
end
