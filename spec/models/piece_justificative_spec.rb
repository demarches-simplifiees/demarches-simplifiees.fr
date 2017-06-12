require 'spec_helper'

describe PieceJustificative do
  describe 'database columns' do
    it { is_expected.to have_db_column(:content) }
    it { is_expected.to have_db_column(:original_filename) }
    it { is_expected.to have_db_column(:content_secure_token) }
    it { is_expected.to have_db_column(:created_at) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_de_piece_justificative) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:commentaire) }
  end

  describe 'validations' do
    context 'content' do
      it { is_expected.not_to allow_value(nil).for(:content) }
      it { is_expected.not_to allow_value('').for(:content) }
    end
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:libelle).to(:type_de_piece_justificative) }
    it { is_expected.to delegate_method(:api_entreprise).to(:type_de_piece_justificative) }
  end

  describe '#empty?', vcr: { cassette_name: 'model_piece_justificative' } do
    let(:piece_justificative) { create(:piece_justificative, content: content) }
    subject { piece_justificative.empty? }

    context 'when content exist' do
      let(:content) { File.open('./spec/support/files/piece_justificative_388.pdf') }
      it { is_expected.to be_falsey }
    end
  end
end
