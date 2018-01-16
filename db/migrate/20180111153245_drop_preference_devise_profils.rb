class DropPreferenceDeviseProfils < ActiveRecord::Migration[5.0]
  def change
    drop_table :preference_devise_profils
  end
end
