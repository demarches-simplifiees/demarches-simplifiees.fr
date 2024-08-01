# frozen_string_literal: true

class RemoveChampsRowIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :champs, name: "index_champs_on_type_de_champ_id_and_dossier_id_and_row"
  end
end
