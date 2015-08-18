require 'spec_helper'

describe PieceJointe do
  describe 'database columns' do
    it { is_expected.to have_db_column(:content) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_piece_jointe) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:libelle).to(:type_piece_jointe) }
    it { is_expected.to delegate_method(:api_entreprise).to(:type_piece_jointe) }
  end

  describe '#empty?' do
    let(:piece_jointe) { create(:piece_jointe, content: content) }
    subject { piece_jointe.empty? }
    context 'when content is nil' do
      let(:content) { nil }
      it { is_expected.to be_truthy }
    end
    context 'when content exist' do
      let(:content) { File.open('./spec/support/files/piece_jointe_388.pdf') }
      it { is_expected.to be_falsey }
    end
  end
end