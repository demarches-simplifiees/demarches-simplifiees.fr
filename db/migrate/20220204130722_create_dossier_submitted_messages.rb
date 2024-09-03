# frozen_string_literal: true

class CreateDossierSubmittedMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :dossier_submitted_messages do |t|
      t.string :message_on_submit_by_usager
      t.timestamps
    end
    add_reference :procedure_revisions, :dossier_submitted_message, foreign_key: { to_table: :dossier_submitted_messages }, null: true, index: true
  end
end
