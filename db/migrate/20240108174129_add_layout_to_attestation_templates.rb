class AddLayoutToAttestationTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :attestation_templates, :official_layout, :boolean, default: true, null: false
  end
end
