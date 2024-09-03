# frozen_string_literal: true

class AddLabelsToAttestationTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :attestation_templates, :label_logo, :string, default: nil
    add_column :attestation_templates, :label_direction, :string, default: nil
  end
end
