# frozen_string_literal: true

describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default_and_errors' do
    let(:procedure) { create(:procedure) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: create(:instructeur)) }

    let(:procedure_presentation_and_errors) { assign_to.procedure_presentation_or_default_and_errors }
    let(:procedure_presentation_or_default) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context "without a procedure_presentation" do
      it { expect(procedure_presentation_or_default).to be_persisted }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_nil }
    end

    context "with a procedure_presentation" do
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to) }

      it { expect(procedure_presentation_or_default).to eq(procedure_presentation) }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_nil }
    end

    context "with an invalid procedure_presentation" do
      let!(:procedure_presentation) do
        pp = ProcedurePresentation.new(assign_to: assign_to, displayed_fields: [{ 'table' => 'invalid', 'column' => 'random' }])
        pp.save(validate: false)
        pp
      end

      it { expect(procedure_presentation_or_default).to be_persisted }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_present }
      it do
        procedure_presentation_or_default
        expect(assign_to.procedure_presentation).not_to be(procedure_presentation)
      end
    end
  end

  describe '#cancel_notifications_for_inactive_instructeurs' do
    let(:period) { AssignTo::MIN_INACTIVE_DAYS + 1 }
    let(:procedure) { create(:procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur:, updated_at: period.days.ago) }
    describe "for instructeurs without followed dossier" do
      it "cancel notifications" do
        expect(assign_to.instant_email_dossier_notifications_enabled).to eq(true)
        AssignTo.cancel_notifications_for_inactive_instructeurs
        assign_to.reload
        expect(assign_to.instant_email_dossier_notifications_enabled).to eq(false)
      end
    end
    describe "for instructeurs who followed dossiers more than X days ago" do
      let(:dossier) { create(:dossier, procedure:) }

      it "cancel notifications" do
        old_date = period.days.ago
        instructeur.follow(dossier)
        instructeur.follows.first.update(demande_seen_at: old_date, annotations_privees_seen_at: old_date, avis_seen_at: old_date, messagerie_seen_at: old_date)
        expect(assign_to.instant_email_dossier_notifications_enabled).to eq(true)
        AssignTo.cancel_notifications_for_inactive_instructeurs
        assign_to.reload
        expect(assign_to.instant_email_dossier_notifications_enabled).to eq(false)
      end
    end
  end
end
