# frozen_string_literal: true

class RemoveProcedureIdFromAssignTos < ActiveRecord::Migration[6.1]
  def change
    remove_column :assign_tos, :procedure_id, :number
  end
end
