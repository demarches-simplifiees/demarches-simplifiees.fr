require 'spec_helper'

describe TypePieceJointe do
  describe 'database columns' do
    it { is_expected.to have_db_column(:CERFA) }
    it { is_expected.to have_db_column(:nature) }
    it { is_expected.to have_db_column(:libelle_complet) }
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:etablissement) }
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:demarche) }
    it { is_expected.to have_db_column(:administration_emetrice) }
    it { is_expected.to have_db_column(:api_entreprise) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:pieces_jointes) }
    it { is_expected.to belong_to(:formulaire) }
  end
end