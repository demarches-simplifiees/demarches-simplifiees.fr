# frozen_string_literal: true

class AddLayoutToAttestationTemplates < ActiveRecord::Migration[7.0]
  def change
    safety_assured { add_column :attestation_templates, :official_layout, :boolean, default: true, null: false }
  end
end
