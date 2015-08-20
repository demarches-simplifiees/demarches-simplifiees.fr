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
    it { is_expected.to have_one(:cerfa) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:siren).to(:entreprise) }
    it { is_expected.to delegate_method(:siret).to(:etablissement) }
    it { is_expected.to delegate_method(:types_piece_jointe).to(:formulaire) }
  end

  let(:dossier) { create(:dossier, :with_entreprise) }

  let(:entreprise) { dossier.entreprise }
  let(:etablissement) { dossier.etablissement }

  subject { dossier }

  describe '#types_piece_jointe' do
    subject { dossier.types_piece_jointe }
    it 'returns list of required piece justificative' do
      expect(subject.size).to eq(7)
      expect(subject).to include(TypePieceJointe.find(103))
    end
  end

  describe 'creation' do
    it 'create default cerfa' do
      expect { described_class.create }.to change { Cerfa.count }.by(1)
    end

    it 'link cerfa to dossier' do
      dossier = described_class.create
      expect(dossier.cerfa).to eq(Cerfa.last)
    end
  end

  describe '#retrieve_piece_jointe_by_type' do
    let(:type) { 93 }
    subject { dossier.retrieve_piece_jointe_by_type type }
    before do
      dossier.build_default_pieces_jointes
    end

    it 'returns piece jointe with given type' do
      expect(subject.type).to eq(93)
    end
  end

  describe '#build_default_pieces_jointes' do
    context 'when dossier is linked to a formualire' do
      let(:dossier) { create(:dossier) }
      before do
        dossier.build_default_pieces_jointes
      end
      it 'build all pieces jointes needed' do
        expect(dossier.pieces_jointes.count).to eq(7)
      end
    end
  end
end
