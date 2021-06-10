class AddAPIParticulierSourcesToIndividual < ActiveRecord::Migration[6.0]
  def change
    add_column :individuals, :api_particulier_dgfip_numero_fiscal, :string
    add_column :individuals, :api_particulier_dgfip_reference_de_l_avis, :string
    add_column :individuals, :api_particulier_caf_numero_d_allocataire, :string
    add_column :individuals, :api_particulier_caf_code_postal, :string
    add_column :individuals, :api_particulier_pole_emploi_identifiant, :string
    add_column :individuals, :api_particulier_mesri_ine, :string
  end
end
