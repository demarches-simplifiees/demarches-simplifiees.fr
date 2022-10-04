describe DossierPreloader do
  let(:types_de_champ) do
    [
      { type: :text },
      { type: :repetition, children: [{ type: :text }] }
    ]
  end
  let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:repetition) { subject.champs.second }
  let(:first_child) { subject.champs.second.champs.first }

  describe 'all' do
    subject { DossierPreloader.new([dossier]).all.first }

    before { subject }

    it do
      count = 0

      callback = lambda { |*_args| count += 1 }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(subject.id).to eq(dossier.id)
        expect(subject.champs.size).to eq(types_de_champ.size)
        expect(subject.changed?).to be false

        expect(first_child.type).to eq('Champs::TextChamp')
        expect(repetition.id).not_to eq(first_child.id)
        expect(subject.champs.first.dossier).to eq(subject)
        expect(first_child.parent).to eq(repetition)
      end

      expect(count).to eq(0)
    end
  end
end
