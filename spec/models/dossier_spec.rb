require 'spec_helper'

describe Dossier do
  describe 'database columns' do
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:autorisation_donnees) }
    it { is_expected.to have_db_column(:position_lat) }
    it { is_expected.to have_db_column(:position_lon) }
    it { is_expected.to have_db_column(:nom_projet) }
    it { is_expected.to have_db_column(:montant_projet) }
    it { is_expected.to have_db_column(:montant_aide_demande) }
    it { is_expected.to have_db_column(:date_previsionnelle).of_type(:date) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:procedure) }
    it { is_expected.to have_many(:pieces_justificatives) }
    it { is_expected.to have_many(:commentaires) }
    it { is_expected.to have_one(:cerfa) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:siren).to(:entreprise) }
    it { is_expected.to delegate_method(:siret).to(:etablissement) }
    it { is_expected.to delegate_method(:types_de_piece_justificative).to(:procedure) }
  end

  describe 'validation' do
    context 'nom_projet' do
      it { is_expected.to allow_value(nil).for(:nom_projet) }
      it { is_expected.not_to allow_value('').for(:nom_projet) }
      it { is_expected.to allow_value('mon super projet').for(:nom_projet) }
    end
    context 'description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('ma superbe description').for(:description) }
    end
    context 'montant_projet' do
      it { is_expected.to allow_value(nil).for(:montant_projet) }
      it { is_expected.not_to allow_value('').for(:montant_projet) }
      it { is_expected.to allow_value(124324).for(:montant_projet) }
    end
    context 'montant_aide_demande' do
      it { is_expected.to allow_value(nil).for(:montant_aide_demande) }
      it { is_expected.not_to allow_value('').for(:montant_aide_demande) }
      it { is_expected.to allow_value(124324).for(:montant_aide_demande) }
    end
  end

  describe 'methods' do
    let(:dossier) { create(:dossier, :with_entreprise, :with_procedure) }

    let(:entreprise) { dossier.entreprise }
    let(:etablissement) { dossier.etablissement }

    subject { dossier }

    describe '#types_de_piece_justificative' do
      subject { dossier.types_de_piece_justificative }
      it 'returns list of required piece justificative' do
        expect(subject.size).to eq(2)
        expect(subject).to include(TypeDePieceJustificative.find(TypeDePieceJustificative.first.id))
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

    describe '#retrieve_piece_justificative_by_type' do
      let(:all_dossier_pj_id){dossier.procedure.types_de_piece_justificative}
      subject { dossier.retrieve_piece_justificative_by_type all_dossier_pj_id.first }
      before do
        dossier.build_default_pieces_justificatives
      end

      it 'returns piece justificative with given type' do
        expect(subject.type).to eq(all_dossier_pj_id.first.id)
      end
    end

    describe '#build_default_pieces_justificatives' do
      context 'when dossier is linked to a procedure' do
        let(:dossier) { create(:dossier, :with_procedure) }
        it 'build all pieces justificatives needed' do
          expect(dossier.pieces_justificatives.count).to eq(2)
        end
      end
    end

    describe '#save' do
      subject { create(:dossier, procedure_id: nil) }
      context 'when is linked to a procedure' do
        it 'creates default pieces justificatives' do
          expect(subject).to receive(:build_default_pieces_justificatives)
          subject.update_attributes(procedure_id: 1)
        end
      end
      context 'when is not linked to a procedure' do
        it 'does not create default pieces justificatives' do
          expect(subject).not_to receive(:build_default_pieces_justificatives)
          subject.update_attributes(description: 'plop')
        end
      end
    end
  end
end
