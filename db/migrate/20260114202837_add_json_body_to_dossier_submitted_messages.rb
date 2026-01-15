# frozen_string_literal: true

class AddJSONBodyToDossierSubmittedMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :dossier_submitted_messages, :json_body, :jsonb
  end
end
