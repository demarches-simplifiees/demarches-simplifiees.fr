# frozen_string_literal: true

describe GroupeInstructeur, type: :model do
  let(:admin) { create :administrateur }
  let(:procedure) { create :procedure, :published, administrateur: admin }
  let(:procedure_2) { create :procedure, :published, administrateur: admin }
  let(:procedure_3) { create :procedure, :published, administrateur: admin }
  let(:instructeur) { create :instructeur, administrateurs: [admin] }
  let(:procedure_assign) { assign(procedure) }

  before do
    procedure_assign
    assign(procedure_2)
    procedure_3
  end

  subject { GroupeInstructeur.new(label: label, procedure: procedure) }

  context 'with no label provided' do
    let(:label) { '' }

    it { is_expected.to be_invalid }
  end

  context 'with a valid label' do
    let(:label) { 'Préfecture de la Marne' }

    it { is_expected.to be_valid }
  end

  context 'with a label with extra spaces' do
    let(:label) { 'Préfecture de la Marne      ' }
    before do
      subject.save
      subject.reload
    end

    it { is_expected.to be_valid }
    it { expect(subject.label).to eq("Préfecture de la Marne") }
  end

  context 'with a label already used for this procedure' do
    let(:label) { 'Préfecture de la Marne' }
    before do
      GroupeInstructeur.create!(label: label, procedure: procedure)
    end

    it { is_expected.to be_invalid }
  end

  describe "#add" do
    let(:another_groupe_instructeur) { create(:groupe_instructeur, procedure: procedure) }

    subject { another_groupe_instructeur.add(instructeur) }

    it 'adds the instructeur to the groupe instructeur' do
      subject
      expect(another_groupe_instructeur.reload.instructeurs).to include(instructeur)
    end

    context 'when joining another groupe instructeur on the same procedure' do
      before do
        procedure_assign.update(daily_email_notifications_enabled: true)
        subject
      end

      it 'copies notifications settings from a previous group' do
        expect(instructeur.assign_to.last.daily_email_notifications_enabled).to be_truthy
      end
    end

    context "when there are dossiers en construction not followed" do
      let!(:dossier) { create(:dossier, :en_construction, groupe_instructeur: another_groupe_instructeur) }

      it "create dossier_depose notification for the added instructeur" do
        subject
        expect(DossierNotification.count).to eq(1)

        notification = DossierNotification.first
        expect(notification.dossier_id).to eq(dossier.id)
        expect(notification.instructeur_id).to eq(instructeur.id)
        expect(notification.notification_type).to eq('dossier_depose')
      end
    end
  end

  describe "#remove" do
    subject { procedure_to_remove.defaut_groupe_instructeur.remove(instructeur) }

    context "with an assigned procedure" do
      let(:procedure_to_remove) { procedure }
      let!(:procedure_presentation) { procedure_assign.procedure_presentation }

      it { is_expected.to be_truthy }

      describe "consequences" do
        before do
          procedure_assign.build_procedure_presentation
          procedure_assign.save
          subject
        end

        it "removes the assign_to and procedure_presentation" do
          expect(AssignTo.where(id: procedure_assign).count).to eq(0)
          expect(ProcedurePresentation.where(assign_to_id: procedure_assign.id).count).to eq(0)
        end
      end
    end

    context "with an already unassigned procedure" do
      let(:procedure_to_remove) { procedure_3 }

      it { is_expected.to be_falsey }
    end

    context "when there are notifications for the instructeur" do
      let(:procedure_to_remove) { procedure }
      let(:groupe_instructeur) { procedure_to_remove.defaut_groupe_instructeur }
      let!(:dossier) { create(:dossier, groupe_instructeur:) }
      let!(:other_instructeur) { create(:instructeur) }
      let!(:notification_instructeur) { create(:dossier_notification, :for_instructeur, dossier:, instructeur:) }
      let!(:notification_other_instructeur) { create(:dossier_notification, :for_instructeur, dossier:, instructeur: other_instructeur) }

      before { procedure_to_remove.defaut_groupe_instructeur.add(other_instructeur) }

      it "destroy notifications only for the instructeur removed" do
        subject

        expect(
          DossierNotification.exists?(instructeur:, dossier:)
        ).to be_falsey

        expect(
          DossierNotification.exists?(instructeur: other_instructeur, dossier:)
        ).to be_truthy
      end
    end
  end

  describe "active group validations" do
    let(:gi_active) { procedure.defaut_groupe_instructeur }
    let(:gi_closed) { create(:groupe_instructeur, procedure:) }

    before do
      gi_active
      gi_closed.update(closed: true)
    end

    context "there is one active groupe instructeur" do
      it "closed is valid when there is one other active groupe" do
        expect(gi_active).to be_valid
        expect(gi_closed).to be_valid
      end

      it "closed is invalid when there is no active groupe" do
        gi_active.closed = true
        expect(gi_active).not_to be_valid
      end
    end

    context "there are many active groupes instructeurs" do
      let!(:second_gi_active) { create(:groupe_instructeur, procedure:) }

      it "closed is invalid for defaut groupe instructeur even if many active groupes" do
        gi_active.update(closed: true)
        expect(gi_active).not_to be_valid
      end
    end
  end

  describe 'destroy' do
    context 'with contact information' do
      let(:defaut_group) { procedure.defaut_groupe_instructeur }
      let(:second_group) { create(:groupe_instructeur, procedure:) }

      before do
        second_group.update(contact_information: create(:contact_information))
      end

      it 'works' do
        expect { second_group.destroy! }.not_to raise_error
      end
    end
  end

  private

  def assign(procedure_to_assign, instructeur_assigne: instructeur)
    create :assign_to, instructeur: instructeur_assigne, procedure: procedure_to_assign, groupe_instructeur: procedure_to_assign.defaut_groupe_instructeur
  end
end
