# frozen_string_literal: true

class AddDeposeAtToDeletedDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :deleted_dossiers, :depose_at, :date
  end
end
