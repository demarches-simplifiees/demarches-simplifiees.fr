# frozen_string_literal: true

class AddIndexOnProcedureIdAndClosedToGroupeInstructeurs < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :groupe_instructeurs, [:closed, :procedure_id]
  end
end
