# frozen_string_literal: true

class AddProcedurePresentationSnapshotToExports < ActiveRecord::Migration[6.1]
  def change
    add_column :exports, :procedure_presentation_snapshot, :jsonb
  end
end
