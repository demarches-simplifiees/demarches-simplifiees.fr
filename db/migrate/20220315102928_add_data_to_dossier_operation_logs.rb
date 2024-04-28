# frozen_string_literal: true

class AddDataToDossierOperationLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :dossier_operation_logs, :data, :jsonb
  end
end
