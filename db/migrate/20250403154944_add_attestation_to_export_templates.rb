# frozen_string_literal: true

class AddAttestationToExportTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :export_templates, :attestation, :jsonb, default: nil
  end
end
