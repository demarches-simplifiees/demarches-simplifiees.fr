# frozen_string_literal: true

class AddUniqIndexOnAttestationDossierId < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    remove_index :attestations, :dossier_id
    add_concurrent_index :attestations, :dossier_id, unique: true
  end
end
