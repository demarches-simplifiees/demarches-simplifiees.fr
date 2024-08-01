# frozen_string_literal: true

class BackfillExportStatus < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Export.in_batches do |relation|
      relation.update_all statut: "tous"
      sleep(0.01)
    end
  end
end
