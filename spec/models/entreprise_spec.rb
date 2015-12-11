require 'spec_helper'

describe Entreprise do
  describe 'databse columns' do
    it { is_expected.to have_db_column(:siren) }
    it { is_expected.to have_db_column(:capital_social) }
    it { is_expected.to have_db_column(:numero_tva_intracommunautaire) }
    it { is_expected.to have_db_column(:forme_juridique) }
    it { is_expected.to have_db_column(:forme_juridique_code) }
    it { is_expected.to have_db_column(:nom_commercial) }
    it { is_expected.to have_db_column(:raison_sociale) }
    it { is_expected.to have_db_column(:siret_siege_social) }
    it { is_expected.to have_db_column(:code_effectif_entreprise) }
    it { is_expected.to have_db_column(:date_creation) }
    it { is_expected.to have_db_column(:nom) }
    it { is_expected.to have_db_column(:prenom) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:rna_information) }
  end
end
