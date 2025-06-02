# frozen_string_literal: true

class AddJSONBodyColumnToAttestationTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :attestation_templates, :json_body, :jsonb
  end
end
