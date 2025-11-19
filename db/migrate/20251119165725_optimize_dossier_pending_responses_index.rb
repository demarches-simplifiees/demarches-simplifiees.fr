# frozen_string_literal: true

class OptimizeDossierPendingResponsesIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    remove_index :dossier_pending_responses, name: "index_dossier_pending_responses_on_responded_at", algorithm: :concurrently

    add_index :dossier_pending_responses, :responded_at, where: "responded_at IS NULL", algorithm: :concurrently, name: "index_dossier_pending_responses_on_responded_at"
  end

  def down
    remove_index :dossier_pending_responses, name: "index_dossier_pending_responses_on_responded_at", algorithm: :concurrently
    add_index :dossier_pending_responses, :responded_at, algorithm: :concurrently, name: "index_dossier_pending_responses_on_responded_at"
  end
end
