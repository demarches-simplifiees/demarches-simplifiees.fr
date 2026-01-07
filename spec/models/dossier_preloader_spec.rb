# frozen_string_literal: true

describe DossierPreloader do
  let(:types_de_champ) do
    [
      { type: :text },
      { type: :repetition, mandatory: true, children: [{ type: :text }] },
      { type: :repetition, mandatory: false, children: [{ type: :text }] },
    ]
  end
  let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ) }
  let(:dossier) { create(:dossier, procedure: procedure) }
  let(:repetition) { subject.project_champs_public.second }
  let(:repetition_optional) { subject.project_champs_public.third }
  let(:first_child) { repetition.rows.first.first }

  describe 'all' do
    subject { DossierPreloader.load_one(dossier, pj_template: true) }

    before { subject }

    it do
      count = 0

      callback = lambda { |*_args| count += 1 }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(subject.id).to eq(dossier.id)
        expect(subject.project_champs_public.size).to eq(types_de_champ.size)
        expect(subject.changed?).to be false

        expect(first_child.type).to eq('Champs::TextChamp')
        expect(repetition).not_to eq(first_child)
        expect(subject.champs.first.dossier).to eq(subject)
        expect(subject.champs.find(&:public?).dossier).to eq(subject)
        expect(subject.project_champs_public.first.dossier).to eq(subject)

        expect(subject.project_champs_public.first.type_de_champ.piece_justificative_template.attached?).to eq(false)

        expect(subject.champs.first.conditional?).to eq(false)
        expect(subject.champs.find(&:public?).conditional?).to eq(false)
        expect(subject.project_champs_public.first.conditional?).to eq(false)

        expect(repetition.rows.first.first.public_id).to eq(first_child.public_id)
        expect(repetition_optional.row_ids).to be_empty
      end

      expect(count).to eq(0)
    end
  end

  describe 'in_batches_with_block' do
    let(:instructeur) { create(:instructeur) }
    let(:expert) { create(:expert) }
    let(:experts_procedure) { create(:experts_procedure, expert:, procedure:) }
    let(:procedure) { create(:procedure, :published, :for_individual, instructeurs: [instructeur]) }

    let!(:dossiers) do
      Array.new(3) do
        dossier = create(:dossier, :en_instruction, :with_individual, procedure:)

        create(:traitement, dossier:, state: :en_instruction)
        create(:commentaire, dossier:, instructeur:)
        create(:commentaire, dossier:, expert:)
        create(:avis, dossier:, claimant: instructeur, experts_procedure:)

        correction_commentaire = create(:commentaire, dossier:, instructeur:)
        create(:dossier_correction, :resolved, dossier:, commentaire: correction_commentaire)

        dossier
      end
    end

    it 'preloads associations for PDF export without N+1' do
      all_dossiers = Dossier.where(id: dossiers.map(&:id))
      loaded_dossiers = []

      DossierPreloader.new(all_dossiers).in_batches_with_block do |batch|
        loaded_dossiers = batch
      end

      count = 0
      callback = lambda { |*_args| count += 1 }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        loaded_dossiers.each do |dossier|
          # Access associations that are used in PDF export
          expect(dossier.individual).to be_present
          expect(dossier.traitement).to be_present
          expect(dossier.association(:pending_corrections).loaded?).to be true
          expect(dossier.commentaires).to be_present
          dossier.commentaires.each do |c|
            c.instructeur&.email
            c.expert&.email
          end
          expect(dossier.avis).to be_present
          dossier.avis.each do |a|
            a.expert&.email
          end
        end
      end

      expect(count).to eq(0)
    end
  end
end
