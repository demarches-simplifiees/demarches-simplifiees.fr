# frozen_string_literal: true

class AdministrateursRemoveEmail < ActiveRecord::Migration[5.2]
  def change
    remove_column :administrateurs, :email
  end
end
