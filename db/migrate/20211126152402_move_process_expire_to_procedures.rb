# frozen_string_literal: true

class MoveProcessExpireToProcedures < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_column :procedures, :procedure_expires_when_termine_enabled, :boolean, default: false
    add_column :traitements, :process_expired_migrated, :boolean, default: false
    add_concurrent_index :procedures, :procedure_expires_when_termine_enabled
  end

  def down
    remove_index :procedures, name: :index_procedures_on_process_expired
    remove_column :traitements, :process_expired_migrated
    remove_column :procedures, :procedure_expires_when_termine_enabled
  end
end
