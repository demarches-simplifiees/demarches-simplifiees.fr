# frozen_string_literal: true

class RenameAdministrationsToSuperAdmins < ActiveRecord::Migration[6.0]
  def change
    rename_table :administrations, :super_admins
  end
end
