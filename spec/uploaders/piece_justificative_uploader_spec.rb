require 'spec_helper'

describe PieceJustificativeUploader do
  let(:pj) { create(:piece_justificative, :rib) }

  it { expect(pj.content.filename).to eq 'piece_justificative.pdf' }

  context 'when extension is nil' do
    it do
      expect(pj.content.file).to receive(:extension).and_return(nil)
      expect(pj.content.filename).to eq 'piece_justificative.'
    end
  end
end
