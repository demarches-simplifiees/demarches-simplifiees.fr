# frozen_string_literal: true

class DropIndexChampsOnDossierIdAndStreamAndStableIdAndRowIdIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :champs, name: :index_champs_on_dossier_id_and_stream_and_stable_id_and_row_id
  end
end
