# frozen_string_literal: true

class RemoveCarrierwaveColumns < ActiveRecord::Migration[5.2]
  def change
    remove_columns :procedures, :logo, :logo_secure_token
    remove_columns :commentaires, :file, :piece_justificative_id
    remove_columns :attestations, :pdf, :content_secure_token
    remove_columns :attestation_templates, :logo, :logo_secure_token, :signature, :signature_secure_token
  end
end
