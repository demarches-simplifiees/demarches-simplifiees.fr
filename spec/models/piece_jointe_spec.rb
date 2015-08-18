require 'spec_helper'

describe PieceJointe do
  describe 'database columns' do
    it { is_expected.to have_db_column(:content) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_piece_jointe) }
  end

  describe 'api_entreprise' do
    let(:type_piece_jointe) { create(:type_piece_jointe, api_entreprise: api_entreprise)}
    let(:piece_jointe) { create(:piece_jointe, type_piece_jointe: type_piece_jointe)}
    subject { piece_jointe.api_entreprise }
    context 'when type_piece_jointe api_entreprise is true' do
      let(:api_entreprise) { true }
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
    context 'when type_piece_jointe api_entreprise is false' do
      let(:api_entreprise) { false }
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end
end