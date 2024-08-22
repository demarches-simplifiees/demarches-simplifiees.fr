# frozen_string_literal: true

class AddReasonToDeletedDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :deleted_dossiers, :reason, :string
  end
end
