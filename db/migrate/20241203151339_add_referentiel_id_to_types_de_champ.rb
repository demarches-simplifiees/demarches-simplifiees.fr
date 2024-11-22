class AddReferentielIdToTypesDeChamp < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :types_de_champ, :referentiel, null: true, default: nil, index: { algorithm: :concurrently }, foreign_key: false
  end
end
