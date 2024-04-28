# frozen_string_literal: true

class AddDossierFolderColumnToExportTemplate < ActiveRecord::Migration[7.0]
  def up
    safety_assured { execute "DELETE FROM export_templates;" }

    add_column :export_templates, :dossier_folder, :jsonb, default: nil, null: false
    add_column :export_templates, :export_pdf, :jsonb, default: nil, null: false
    add_column :export_templates, :pjs, :jsonb, array: true, default: [], null: false
  end

  def down
    remove_column :export_templates, :dossier_folder
    remove_column :export_templates, :export_pdf
    remove_column :export_templates, :pjs
  end
end
