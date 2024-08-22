# frozen_string_literal: true

describe ArchiveHelper, type: :helper do
  describe ".estimate_weight" do
    let(:nb_dossiers_termines) { 5 }
    let(:average_dossier_weight) { 2 }

    context 'when archive exist and available' do
      let(:archive) { build(:archive, :generated) }
      before do
        allow_any_instance_of(Archive).to receive(:available?).and_return(true)
      end

      it 'returns real archive weight' do
        expect(estimate_weight(archive, nb_dossiers_termines, average_dossier_weight)).to eq nil
      end
    end

    context 'when archive has not been created' do
      let(:archive) { nil }
      it 'returns estimation' do
        expect(estimate_weight(archive, nb_dossiers_termines, average_dossier_weight)).to eq 10
      end
    end
  end
end
