class AddHideInstructeurIdentityToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :hide_instructeur_identity, :boolean
  end
end
