# frozen_string_literal: true

class AddHiddenByAdministrationToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :hidden_by_administration_at, :datetime
  end
end
