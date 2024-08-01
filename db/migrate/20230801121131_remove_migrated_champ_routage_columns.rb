# frozen_string_literal: true

class RemoveMigratedChampRoutageColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :procedures, :migrated_champ_routage }
    safety_assured { remove_column :procedure_revisions, :migrated_champ_routage }
    safety_assured { remove_column :dossiers, :migrated_champ_routage }
  end
end
