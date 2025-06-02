# frozen_string_literal: true

class AddClaimantTypeToAvis < ActiveRecord::Migration[6.0]
  def change
    add_column :avis, :claimant_type, :string
    remove_foreign_key :avis, :instructeurs, column: "claimant_id"
  end
end
