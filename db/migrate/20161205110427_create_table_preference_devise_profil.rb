class CreateTablePreferenceDeviseProfil < ActiveRecord::Migration
  def change
    create_table :preference_devise_profils do |t|
      t.string :last_current_devise_profil
    end

    add_belongs_to :preference_devise_profils, :administrateurs
    add_belongs_to :preference_devise_profils, :gestionnaires
    add_belongs_to :preference_devise_profils, :users
  end
end
