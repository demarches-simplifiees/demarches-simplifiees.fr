# frozen_string_literal: true

class AddParentDossierIdToDossier < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :parent_dossier_id, :bigint
  end
end
