# frozen_string_literal: true

class AddPublishedAtToProcedureRevisions < ActiveRecord::Migration[6.0]
  def change
    add_column :procedure_revisions, :published_at, :datetime
  end
end
