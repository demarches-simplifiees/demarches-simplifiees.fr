# frozen_string_literal: true

class AddArchivedAtAndArchivedByToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :archived_at, :datetime
    add_column :dossiers, :archived_by, :string
  end
end
