class ChangeCapitalSocialLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :etablissements, :entreprise_capital_social, :integer, limit: 8
    change_column :entreprises, :capital_social, :integer, limit: 8
  end
end
