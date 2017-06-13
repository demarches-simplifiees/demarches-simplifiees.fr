require 'spec_helper'

describe Etablissement do
  describe 'database columns' do
    it { is_expected.to have_db_column(:siret) }
    it { is_expected.to have_db_column(:siege_social) }
    it { is_expected.to have_db_column(:naf) }
    it { is_expected.to have_db_column(:libelle_naf) }
    it { is_expected.to have_db_column(:adresse) }
    it { is_expected.to have_db_column(:numero_voie) }
    it { is_expected.to have_db_column(:type_voie) }
    it { is_expected.to have_db_column(:nom_voie) }
    it { is_expected.to have_db_column(:complement_adresse) }
    it { is_expected.to have_db_column(:code_postal) }
    it { is_expected.to have_db_column(:localite) }
    it { is_expected.to have_db_column(:code_insee_localite) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:entreprise) }
    it { is_expected.to have_many(:exercices) }
  end

  describe '#geo_adresse' do
    let(:etablissement) { create(:etablissement) }

    subject { etablissement.geo_adresse }

    it { is_expected.to eq '6 RUE RAOUL NORDLING IMMEUBLE BORA 92270 BOIS COLOMBES' }
  end
end
