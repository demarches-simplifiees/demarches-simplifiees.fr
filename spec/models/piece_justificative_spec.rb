require 'spec_helper'

describe PieceJustificative do
  describe 'validations' do
    context 'content' do
      it { is_expected.not_to allow_value(nil).for(:content) }
      it { is_expected.not_to allow_value('').for(:content) }
    end
  end

  describe '#empty?', vcr: { cassette_name: 'model_piece_justificative' } do
    let(:piece_justificative) { create(:piece_justificative, content: content) }
    subject { piece_justificative.empty? }

    context 'when content exist' do
      let(:content) { File.open('./spec/fixtures/files/piece_justificative_388.pdf') }
      it { is_expected.to be_falsey }
    end
  end
end
