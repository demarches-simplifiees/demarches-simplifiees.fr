describe ChampSerializer do
  describe '#attributes' do
    subject { ChampSerializer.new(champ).serializable_hash }

    context 'when type champ is piece justificative' do
      include Rails.application.routes.url_helpers

      let(:champ) { create(:champ, type_de_champ: create(:type_de_champ_piece_justificative)) }

      before { champ.piece_justificative_file.attach({ filename: __FILE__, io: File.open(__FILE__) }) }
      after { champ.piece_justificative_file.purge }

      it { is_expected.to include(value: url_for(champ.piece_justificative_file)) }
    end

    context 'when type champ is not piece justificative' do
      let(:champ) { create(:champ, value: "blah") }

      it { is_expected.to include(value: "blah") }
    end
  end
end
