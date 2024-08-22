# frozen_string_literal: true

class AddDepartementToServices < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :services, :departement, :string
    add_index :services, :departement, algorithm: :concurrently
  end
end
