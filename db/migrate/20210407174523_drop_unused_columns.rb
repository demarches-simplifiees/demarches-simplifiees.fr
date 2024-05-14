# frozen_string_literal: true

class DropUnusedColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :avis, :instructeur_id
    remove_column :avis, :tmp_expert_migrated
    remove_column :etablissements, :entreprise_id
    remove_column :procedures, :archived_at
    remove_column :procedures, :csv_export_queued
    remove_column :procedures, :xlsx_export_queued
    remove_column :procedures, :ods_export_queued
  end
end
