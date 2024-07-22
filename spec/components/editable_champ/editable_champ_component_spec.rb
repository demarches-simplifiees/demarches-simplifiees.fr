describe EditableChamp::EditableChampComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
  let(:types_de_champ_public) { [] }
  let(:types_de_champ_private) { [] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }

  let(:component) { described_class.new(form: nil, champ:) }

  describe "editable_champ_controller" do
    let(:controllers) { [] }
    let(:data) { controllers.join(' ') }

    subject { component.send(:stimulus_controller) }

    context 'when an editable public champ' do
      let(:controllers) { ['autosave'] }
      let(:types_de_champ_public) { [{ type: :text }] }

      it { expect(subject).to eq(data) }
    end

    context 'when a repetition champ' do
      let(:types_de_champ_public) { [{ type: :repetition, children: [{ type: :text }] }] }

      it { expect(subject).to eq(nil) }
    end

    context 'when a carte champ' do
      let(:types_de_champ_public) { [{ type: :carte }] }

      it { expect(subject).to eq(nil) }
    end

    context 'when a private champ' do
      let(:types_de_champ_private) { [{ type: :text }] }

      it { expect(subject).to eq('autosave') }
    end

    context 'when a dossier is en_construction' do
      let(:controllers) { ['autosave'] }
      let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }

      context 'when a public dropdown champ' do
        let(:controllers) { ['autosave'] }
        let(:types_de_champ_public) { [{ type: :drop_down_list }] }

        it { expect(subject).to eq(data) }
      end

      context 'when a private dropdown champ' do
        let(:controllers) { ['autosave'] }
        let(:types_de_champ_private) { [{ type: :drop_down_list }] }

        it { expect(subject).to eq(data) }
      end
    end
  end
end
