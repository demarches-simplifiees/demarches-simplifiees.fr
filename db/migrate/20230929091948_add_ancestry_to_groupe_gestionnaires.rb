# frozen_string_literal: true

class AddAncestryToGroupeGestionnaires < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :groupe_gestionnaires, :ancestry, :string, collation: 'C', null: false, default: '/'
      add_index :groupe_gestionnaires, :ancestry, algorithm: :concurrently
    end
  end
end
