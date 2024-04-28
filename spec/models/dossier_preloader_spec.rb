# frozen_string_literal: true

describe DossierPreloader do
  let(:types_de_champ) do
    [
      { type: :text },
      { type: :repetition, mandatory: true, children: [{ type: :text }] },
      { type: :repetition, mandatory: false, children: [{ type: :text }] }
    ]
  end
  let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:repetition) { subject.champs_public.second }
  let(:repetition_optional) { subject.champs_public.third }
  let(:first_child) { subject.champs_public.second.champs.first }

  describe 'all' do
    subject { DossierPreloader.load_one(dossier, pj_template: true) }

    before { subject }

    it do
      count = 0

      callback = lambda { |*_args| count += 1 }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(subject.id).to eq(dossier.id)
        expect(subject.champs_public.size).to eq(types_de_champ.size)
        expect(subject.changed?).to be false

        expect(first_child.type).to eq('Champs::TextChamp')
        expect(repetition.id).not_to eq(first_child.id)
        expect(subject.champs.first.dossier).to eq(subject)
        expect(subject.champs.find(&:public?).dossier).to eq(subject)
        expect(subject.champs_public.first.dossier).to eq(subject)

        expect(subject.champs_public.first.type_de_champ.piece_justificative_template.attached?).to eq(false)

        expect(subject.champs.first.conditional?).to eq(false)
        expect(subject.champs.find(&:public?).conditional?).to eq(false)
        expect(subject.champs_public.first.conditional?).to eq(false)

        expect(first_child.parent).to eq(repetition)
        expect(repetition.champs.first).to eq(first_child)
        expect(repetition_optional.champs).to be_empty
      end

      expect(count).to eq(0)
    end
  end
end
