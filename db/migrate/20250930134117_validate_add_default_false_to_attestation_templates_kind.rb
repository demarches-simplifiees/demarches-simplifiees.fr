# frozen_string_literal: true

class ValidateAddDefaultFalseToAttestationTemplatesKind < ActiveRecord::Migration[7.2]
  def up
    validate_check_constraint :attestation_templates, name: "attestation_templates_kind_null"
    change_column_null :attestation_templates, :kind, false
    remove_check_constraint :attestation_templates, name: "attestation_templates_kind_null"
  end

  def down
    add_check_constraint :attestation_templates, "kind IS NOT NULL", name: "attestation_templates_kind_null", validate: false
    change_column_null :attestation_templates, :kind, true
  end
end
