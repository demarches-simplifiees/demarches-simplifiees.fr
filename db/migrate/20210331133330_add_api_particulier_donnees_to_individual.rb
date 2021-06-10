class AddAPIParticulierDonneesToIndividual < ActiveRecord::Migration[6.0]
  def change
    add_column :individuals, :api_particulier_donnees, :jsonb, :default => {}
    add_index  :individuals, :api_particulier_donnees, using: :gin
  end
end
