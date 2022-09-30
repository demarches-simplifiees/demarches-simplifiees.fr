describe ChampHelper, type: :helper do
  describe "editable_champ_controller" do
    let(:dossier) { create(:dossier) }
    let(:champ) { create(:champ, dossier: dossier) }
    let(:controllers) { [] }
    let(:data) { { controller: controllers.join(' ') } }

    context 'when an editable champ' do
      let(:controllers) { ['autosave'] }

      it { expect(editable_champ_controller(champ)).to eq(data) }
    end

    context 'when a repetition champ' do
      let(:champ) { create(:champ_repetition, dossier: dossier) }

      it { expect(editable_champ_controller(champ)).to eq(nil) }
    end

    context 'when a private champ' do
      let(:champ) { create(:champ, dossier: dossier, private: true) }

      it { expect(editable_champ_controller(champ)).to eq(nil) }
    end

    context 'when a dossier is en_construction' do
      let(:controllers) { ['check-conditions'] }
      let(:dossier) { create(:dossier, :en_construction) }

      it { expect(editable_champ_controller(champ)).to eq(data) }

      context 'when a public dropdown champ' do
        let(:controllers) { ['check-conditions', 'champ-dropdown'] }
        let(:champ) { create(:champ_drop_down_list, dossier: dossier) }

        it { expect(editable_champ_controller(champ)).to eq(data) }
      end

      context 'when a private dropdown champ' do
        let(:controllers) { ['champ-dropdown'] }
        let(:champ) { create(:champ_drop_down_list, dossier: dossier, private: true) }

        it { expect(editable_champ_controller(champ)).to eq(data) }
      end
    end

    context 'when a public dropdown champ' do
      let(:controllers) { ['autosave', 'champ-dropdown'] }
      let(:champ) { create(:champ_drop_down_list, dossier: dossier) }

      it { expect(editable_champ_controller(champ)).to eq(data) }
    end

    context 'when a private dropdown champ' do
      let(:controllers) { ['champ-dropdown'] }
      let(:champ) { create(:champ_drop_down_list, dossier: dossier, private: true) }

      it { expect(editable_champ_controller(champ)).to eq(data) }
    end
  end
end
