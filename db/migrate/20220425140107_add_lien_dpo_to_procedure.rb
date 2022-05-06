class AddLienDpoToProcedure < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :lien_dpo, :string
  end
end
