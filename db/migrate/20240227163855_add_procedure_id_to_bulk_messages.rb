# frozen_string_literal: true

class AddProcedureIdToBulkMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_messages, :procedure_id, :bigint
  end
end
