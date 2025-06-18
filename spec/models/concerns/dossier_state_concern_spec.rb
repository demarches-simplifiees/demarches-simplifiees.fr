# frozen_string_literal: true

RSpec.describe DossierStateConcern do
  include Logic

  let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_public:, declarative_with_state:, auto_archive_on:) }
  let(:types_de_champ_public) do
    [
      { type: :text, stable_id: 90 },
      { type: :text, stable_id: 91 },
      { type: :piece_justificative, stable_id: 92, condition: ds_eq(constant(true), constant(false)) },
      { type: :titre_identite, stable_id: 93, condition: ds_eq(constant(true), constant(false)) },
      { type: :repetition, stable_id: 94, children: [{ type: :text, stable_id: 941 }, { type: :text, stable_id: 942 }] },
      { type: :repetition, stable_id: 95, children: [{ type: :text, stable_id: 951 }] },
      { type: :repetition, stable_id: 96, children: [{ type: :text, stable_id: 961 }], condition: ds_eq(constant(true), constant(false)) },
      { type: :text, stable_id: 97, condition: ds_eq(constant(true), constant(false)) },
      { type: :titre_identite, stable_id: 98 }
    ]
  end
  let(:auto_archive_on) { nil }
  let(:declarative_with_state) { nil }
  let(:dossier_state) { :brouillon }
  let(:dossier) do
    create(:dossier, dossier_state, :with_individual, :with_populated_champs, procedure:).tap do |dossier|
      procedure.draft_revision.remove_type_de_champ(91)
      procedure.draft_revision.remove_type_de_champ(95)
      procedure.draft_revision.remove_type_de_champ(942)
      procedure.publish_revision!
      perform_enqueued_jobs
      dossier.reload
      champ_repetition = dossier.project_champs_public.find { _1.stable_id == 94 }
      row_id = champ_repetition.row_ids.first
      dossier.champs.filter(&:row?).find { _1.row_id == row_id }.touch(:discarded_at)
    end
  end

  describe 'submit brouillon' do
    it do
      expect(dossier.champs.size).to eq(20)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
      expect(dossier.champs.filter { _1.row? && _1.discarded? }.size).to eq(1)
      expect(dossier.champs.filter { _1.row? && _1.stable_id.in?([95, 96]) }.size).to eq(4)
      expect(dossier.champs.filter { _1.stable_id.in?([90, 92, 93, 97, 961, 951]) }.size).to eq(8)

      champ_text = dossier.project_champs_public.find { _1.stable_id == 90 }
      champ_text.update(value: '')

      dossier.passer_en_construction!
      dossier.reload

      expect(dossier.champs.size).to eq(3)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
      expect(dossier.champs.filter { _1.row? && _1.discarded? }.size).to eq(0)
      expect(dossier.champs.filter { _1.row? && _1.stable_id.in?([95, 96]) }.size).to eq(0)
      expect(dossier.champs.filter { _1.stable_id.in?([90, 92, 93, 97, 961, 951]) }.size).to eq(0)
    end
  end

  describe 'submit en construction' do
    let(:dossier_state) { :en_construction }

    it do
      expect(dossier.champs.size).to eq(20)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
      expect(dossier.champs.filter { _1.row? && _1.discarded? }.size).to eq(1)
      expect(dossier.champs.filter { _1.row? && _1.stable_id.in?([95, 96]) }.size).to eq(4)
      expect(dossier.champs.filter { _1.stable_id.in?([92, 93, 97, 961, 951]) }.size).to eq(7)

      dossier.submit_en_construction!
      dossier.reload

      expect(dossier.champs.size).to eq(4)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
      expect(dossier.champs.filter { _1.row? && _1.discarded? }.size).to eq(0)
      expect(dossier.champs.filter { _1.row? && _1.stable_id.in?([95, 96]) }.size).to eq(0)
      expect(dossier.champs.filter { _1.stable_id.in?([92, 93, 97, 961, 951]) }.size).to eq(0)
    end
  end

  describe 'accepter' do
    let(:dossier_state) { :en_instruction }

    it do
      expect(dossier.champs.size).to eq(20)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(2)

      dossier.accepter!(motivation: 'test')
      dossier.reload

      expect(dossier.champs.size).to eq(15)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(0)
    end
  end

  describe 'refuser' do
    let(:dossier_state) { :en_instruction }

    it do
      expect(dossier.champs.size).to eq(20)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(2)

      dossier.refuser!(motivation: 'test')
      dossier.reload

      expect(dossier.champs.size).to eq(15)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(0)
    end
  end

  describe 'classer_sans_suite' do
    let(:dossier_state) { :en_instruction }

    it do
      expect(dossier.champs.size).to eq(20)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(2)

      dossier.classer_sans_suite!(motivation: 'test')
      dossier.reload

      expect(dossier.champs.size).to eq(15)
      expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
      expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(0)
    end
  end

  describe 'automatiquement' do
    let(:dossier_state) { :en_construction }

    describe 'accepter' do
      let(:declarative_with_state) { Dossier.states.fetch(:accepte) }

      it do
        expect(dossier.champs.size).to eq(20)
        expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(2)
        expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(2)

        dossier.accepter_automatiquement!
        dossier.reload

        expect(dossier.champs.size).to eq(15)
        expect(dossier.champs.filter { _1.row? && _1.stable_id == 94 }.size).to eq(1)
        expect(dossier.champs.filter { _1.stable_id.in?([93, 98]) }.size).to eq(0)
      end
    end

    describe 'en_instruction' do
      context "when dossier has a dossier_depose notification" do
        let(:auto_archive_on) { 1.day.from_now }
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, groupe_instructeur_id: dossier.groupe_instructeur_id, dossier:) }

        it "destroy the notification" do
          travel_to(2.days.from_now)
          dossier.passer_automatiquement_en_instruction!

          expect(DossierNotification.count).to eq(0)
        end
      end
    end
  end
end
