# frozen_string_literal: true

class RemoveInstructeurIdAndAddInstructeurEmailToTraitements < ActiveRecord::Migration[5.2]
  def change
    add_column :traitements, :instructeur_email, :string
    remove_column :traitements, :instructeur_id
  end
end
