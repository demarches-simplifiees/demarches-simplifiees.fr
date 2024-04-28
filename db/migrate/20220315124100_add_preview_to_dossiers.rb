# frozen_string_literal: true

class AddPreviewToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :for_procedure_preview, :boolean
    change_column_default :dossiers, :for_procedure_preview, false
  end
end
