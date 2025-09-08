class AddTypeToAttestationTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :attestation_templates, :type, :string
  end
end
