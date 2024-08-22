# frozen_string_literal: true

class AddPartialIndexOnDol < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :dossier_operation_logs, :id, where: 'data is not null', algorithm: :concurrently
  end
end
