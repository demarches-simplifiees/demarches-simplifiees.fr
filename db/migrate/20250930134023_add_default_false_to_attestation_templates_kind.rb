# frozen_string_literal: true

class AddDefaultFalseToAttestationTemplatesKind < ActiveRecord::Migration[7.2]
  def change
    add_check_constraint :attestation_templates, "kind IS NOT NULL", name: "attestation_templates_kind_null", validate: false
  end
end
