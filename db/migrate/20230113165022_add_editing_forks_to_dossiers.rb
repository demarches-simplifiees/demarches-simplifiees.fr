# frozen_string_literal: true

class AddEditingForksToDossiers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_belongs_to :dossiers, :editing_fork_origin, null: true, index: { algorithm: :concurrently }
  end
end
