# frozen_string_literal: true

class AddPublishedByAdministrateurToProcedureRevisions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :procedure_revisions, :administrateur, null: true, default: nil, index: { algorithm: :concurrently }, foreign_key: false
  end
end
