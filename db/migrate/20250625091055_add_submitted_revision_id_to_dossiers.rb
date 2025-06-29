# frozen_string_literal: true

class AddSubmittedRevisionIdToDossiers < ActiveRecord::Migration[7.1]
  def change
    add_column :dossiers, :submitted_revision_id, :bigint, null: true
  end
end
