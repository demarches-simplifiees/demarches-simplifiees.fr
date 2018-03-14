class DropPreferenceDeviseProfils < ActiveRecord::Migration[5.2]
  def change
    drop_table :preference_devise_profils
  end
end
