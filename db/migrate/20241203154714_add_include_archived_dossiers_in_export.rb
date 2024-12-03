# frozen_string_literal: true

class AddIncludeArchivedDossiersInExport < ActiveRecord::Migration[7.0]
  def change
    add_column :exports, :include_archived, :boolean, default: false, null: false
  end
end
