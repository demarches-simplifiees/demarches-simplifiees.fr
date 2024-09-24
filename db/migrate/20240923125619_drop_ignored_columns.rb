# frozen_string_literal: true

class DropIgnoredColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :dossiers, :re_instructed_at
      remove_column :instructeurs, :agent_connect_id
      remove_column :procedures, :direction
      remove_column :procedures, :durees_conservation_required
      remove_column :procedures, :cerfa_flag
      remove_column :procedures, :test_started_at
      remove_column :procedures, :lien_demarche
      remove_column :traitements, :process_expired
      remove_column :traitements, :process_expired_migrated
      remove_column :active_storage_blobs, :lock_version
    end
  end
end
