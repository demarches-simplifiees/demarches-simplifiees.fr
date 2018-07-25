class AddSearchTermsToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :search_terms, :text
    add_column :dossiers, :private_search_terms, :text
    add_index :dossiers, "to_tsvector('french', search_terms)", using: :gin, name: 'index_dossiers_on_search_terms'
    add_index :dossiers, "to_tsvector('french', search_terms || private_search_terms)", using: :gin, name: 'index_dossiers_on_search_terms_private_search_terms'
  end
end
