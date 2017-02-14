class CreateSearches < ActiveRecord::Migration
  def up
    add_index :champs, :dossier_id
    add_index :champs, :type_de_champ_id
    add_index :drop_down_lists, :type_de_champ_id
    add_index :etablissements, :dossier_id
    add_index :entreprises, :dossier_id
    add_index :france_connect_informations, :user_id
    add_index :individuals, :dossier_id
    add_index :pieces_justificatives, :dossier_id
    add_index :rna_informations, :entreprise_id
    create_view :searches unless Rails.env.test? #, materialized: true
  end

  def down
    remove_index :champs, :dossier_id
    remove_index :champs, :type_de_champ_id
    remove_index :drop_down_lists, :type_de_champ_id
    remove_index :etablissements, :dossier_id
    remove_index :entreprises, :dossier_id
    remove_index :france_connect_informations, :user_id
    remove_index :individuals, :dossier_id
    remove_index :pieces_justificatives, :dossier_id
    remove_index :rna_informations, :entreprise_id
    drop_view :searches unless Rails.env.test? #, materialized: true
  end
end
