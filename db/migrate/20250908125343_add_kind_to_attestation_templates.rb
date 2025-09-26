# frozen_string_literal: true

class AddKindToAttestationTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :attestation_templates, :kind, :string
  end
end
