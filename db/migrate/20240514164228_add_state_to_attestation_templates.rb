# frozen_string_literal: true

class AddStateToAttestationTemplates < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :attestation_templates, :state, :string, default: 'published'
    end
  end
end
