require 'spec_helper'

describe Dossier do

  describe 'database columns' do
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:autorisation_donnees) }
    it { is_expected.to have_db_column(:position_lat) }
    it { is_expected.to have_db_column(:position_lon) }
    it { is_expected.to have_db_column(:ref_dossier) }
    it { is_expected.to have_db_column(:nom_projet) }
    it { is_expected.to have_db_column(:montant_projet) }
    it { is_expected.to have_db_column(:montant_aide_demande) }
    it { is_expected.to have_db_column(:date_previsionnelle) }
    it { is_expected.to have_db_column(:lien_plus_infos) }
    it { is_expected.to have_db_column(:mail_contact) }
    it { is_expected.to have_db_column(:dossier_termine) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:formulaire) }
    it { is_expected.to have_many(:pieces_jointes) }
    it { is_expected.to have_many(:commentaires) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
  end

  let(:dossier) { create(:dossier, :with_entreprise) }

  let(:entreprise) { dossier.entreprise }
  let(:etablissement) { dossier.etablissement }

  subject { dossier }

  describe '#siren' do
    it 'returns entreprise siren' do
      expect(subject.siren).to eq(entreprise.siren)
    end
  end

  describe '#siret' do
    it 'returns etablissement siret' do
      expect(subject.siret).to eq(etablissement.siret)
    end
  end

  describe '#types_piece_jointe' do
    subject { dossier.types_piece_jointe }
    it 'returns list of required piece justificative' do
      expect(subject.size).to eq(7)
      expect(subject).to include(TypePieceJointe.find(103))
    end
  end
end