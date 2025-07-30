# frozen_string_literal: true

class AddOtherFilesToExportTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :export_templates, :commentaires_attachments, :boolean, default: false, null: false
    add_column :export_templates, :avis_attachments, :boolean, default: false, null: false
    add_column :export_templates, :justificatif_motivation, :boolean, default: false, null: false
  end
end
