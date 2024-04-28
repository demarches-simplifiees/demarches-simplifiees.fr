# frozen_string_literal: true

class AddIndexOnDossierIdToInvites < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :invites, [:dossier_id]
  end
end
