# frozen_string_literal: true

class BackfillAddOpendataToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Procedure.in_batches do |relation|
      relation.update_all opendata: true
      sleep(0.01)
    end
  end
end
