describe EditableChamp::EditableChampComponent, type: :component do
  let(:component) { described_class.new(form: nil, champ: champ) }

  describe "editable_champ_controller" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ, dossier: dossier) }
    let(:controllers) { [] }
    let(:data) { controllers.join(' ') }

    subject { component.send(:stimulus_controller) }

    context 'when an editable champ' do
      let(:controllers) { ['autosave'] }

      it { expect(subject).to eq(data) }
    end

    context 'when a repetition champ' do
      let(:champ) { create(:champ_repetition, dossier: dossier) }

      it { expect(subject).to eq(nil) }
    end

    context 'when a carte champ' do
      let(:champ) { create(:champ_carte, dossier: dossier) }

      it { expect(subject).to eq(nil) }
    end

    context 'when a private champ' do
      let(:champ) { create(:champ, dossier: dossier, private: true) }

      it { expect(subject).to eq('autosave') }
    end

    context 'when a dossier is en_construction' do
      let(:controllers) { ['autosave'] }
      let(:dossier) { create(:dossier, :en_construction) }

      it { expect(subject).to eq(data) }

      context 'when a public dropdown champ' do
        let(:controllers) { ['autosave'] }
        let(:champ) { create(:champ_drop_down_list, dossier: dossier) }

        it { expect(subject).to eq(data) }
      end

      context 'when a private dropdown champ' do
        let(:controllers) { ['autosave'] }
        let(:champ) { create(:champ_drop_down_list, dossier: dossier, private: true) }

        it { expect(subject).to eq(data) }
      end
    end

    context 'when a public dropdown champ' do
      let(:controllers) { ['autosave'] }
      let(:champ) { create(:champ_drop_down_list, dossier: dossier) }

      it { expect(subject).to eq(data) }
    end

    context 'when a private dropdown champ' do
      let(:controllers) { ['autosave'] }
      let(:champ) { create(:champ_drop_down_list, dossier: dossier, private: true) }

      it { expect(subject).to eq(data) }
    end
  end
end
