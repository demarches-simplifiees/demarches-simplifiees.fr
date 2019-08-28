require 'spec_helper'

describe Instructeur, type: :model do
  let(:admin) { create :administrateur }
  let!(:procedure) { create :procedure, :published, administrateur: admin }
  let!(:procedure_2) { create :procedure, :published, administrateur: admin }
  let!(:procedure_3) { create :procedure, :published, administrateur: admin }
  let(:instructeur) { create :instructeur, administrateurs: [admin] }
  let!(:procedure_assign) { assign(procedure) }

  before do
    assign(procedure_2)
  end

  describe '#visible_procedures' do
    let(:procedure_not_assigned)           { create :procedure, administrateur: admin }
    let(:procedure_with_default_path)      { create :procedure, administrateur: admin }
    let(:procedure_with_custom_path)       { create :procedure, :with_path, administrateur: admin }
    let(:procedure_archived_manually)      { create :procedure, :archived, administrateur: admin }
    let(:procedure_archived_automatically) { create :procedure, :archived_automatically, administrateur: admin }

    before do
      assign(procedure_with_default_path)
      assign(procedure_with_custom_path)
      assign(procedure_archived_manually)
      assign(procedure_archived_automatically)
    end

    subject { instructeur.visible_procedures }

    it do
      expect(subject).not_to include(procedure_not_assigned)
      expect(subject).to include(procedure_with_default_path)
      expect(subject).to include(procedure_with_custom_path)
      expect(subject).to include(procedure_archived_manually)
      expect(subject).to include(procedure_archived_automatically)
    end
  end

  describe 'follow' do
    let(:dossier) { create :dossier }
    let(:already_followed_dossier) { create :dossier }

    before { instructeur.followed_dossiers << already_followed_dossier }

    context 'when a instructeur follow a dossier for the first time' do
      before { instructeur.follow(dossier) }

      it { expect(instructeur.follow?(dossier)).to be true }
    end

    context 'when a instructeur follows a dossier already followed' do
      before { instructeur.follow(already_followed_dossier) }

      it { expect(instructeur.follow?(already_followed_dossier)).to be true }
    end
  end

  describe '#unfollow' do
    let(:already_followed_dossier) { create(:dossier) }
    before { instructeur.followed_dossiers << already_followed_dossier }

    context 'when a instructeur unfollow a dossier already followed' do
      before do
        instructeur.unfollow(already_followed_dossier)
        already_followed_dossier.reload
      end

      it { expect(instructeur.follow?(already_followed_dossier)).to be false }
      it { expect(instructeur.previously_followed_dossiers).to include(already_followed_dossier) }
    end
  end

  describe '#follow?' do
    let!(:dossier) { create :dossier, procedure: procedure }

    subject { instructeur.follow?(dossier) }

    context 'when instructeur follow a dossier' do
      before do
        create :follow, dossier_id: dossier.id, instructeur_id: instructeur.id
      end

      it { is_expected.to be_truthy }
    end

    context 'when instructeur not follow a dossier' do
      it { is_expected.to be_falsey }
    end
  end

  describe "#assign_to_procedure" do
    subject { instructeur.assign_to_procedure(procedure_to_assign) }

    context "with a procedure not already assigned" do
      let(:procedure_to_assign) { procedure_3 }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change(instructeur.procedures, :count) }
      it do
        subject
        expect(instructeur.groupe_instructeurs).to include(procedure_to_assign.defaut_groupe_instructeur)
      end
    end

    context "with an already assigned procedure" do
      let(:procedure_to_assign) { procedure }

      it { is_expected.to be_falsey }
      it { expect { subject }.not_to change(instructeur.procedures, :count) }
    end
  end

  describe "#remove_from_procedure" do
    subject { instructeur.remove_from_procedure(procedure_to_remove) }

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
  end

  describe 'last_week_overview' do
    let!(:instructeur2) { create(:instructeur) }
    subject { instructeur2.last_week_overview }
    let(:friday) { Time.zone.local(2017, 5, 12) }
    let(:monday) { Time.zone.now.beginning_of_week }

    before { Timecop.freeze(friday) }
    after { Timecop.return }

    context 'when no procedure published was active last week' do
      let!(:procedure) { create(:procedure, :published, libelle: 'procedure') }

      before { instructeur2.assign_to_procedure(procedure) }

      context 'when the instructeur has no notifications' do
        it { is_expected.to eq(nil) }
      end
    end

    context 'when a procedure published was active' do
      let!(:procedure) { create(:procedure, :published, libelle: 'procedure') }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        instructeur2.assign_to_procedure(procedure)
        expect_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { expect(instructeur2.last_week_overview[:procedure_overviews]).to match([procedure_overview]) }
    end

    context 'when a procedure not published was active with no notifications' do
      let!(:procedure) { create(:procedure, libelle: 'procedure') }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        instructeur2.assign_to_procedure(procedure)
        allow_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe "procedure_presentation_and_errors_for_groupe_instructeur_id" do
    let(:procedure_presentation_and_errors) { instructeur.procedure_presentation_and_errors_for_groupe_instructeur_id(procedure.defaut_groupe_instructeur.id) }
    let(:procedure_presentation) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context 'with explicit presentation' do
      let(:procedure_id) { procedure.id }
      let!(:pp) { ProcedurePresentation.create(assign_to: procedure_assign) }

      it { expect(procedure_presentation).to eq(pp) }
      it { expect(errors).to be_nil }
    end

    context 'with invalid presentation' do
      let(:procedure_id) { procedure.id }
      before do
        pp = ProcedurePresentation.create(assign_to: procedure_assign, displayed_fields: [{ 'table' => 'invalid', 'column' => 'random' }])
        pp.save(:validate => false)
      end

      it { expect(procedure_presentation).not_to be_persisted }
      it { expect(errors).to be_present }
    end

    context 'with default presentation' do
      let(:procedure_id) { procedure_2.id }

      it { expect(procedure_presentation).not_to be_persisted }
      it { expect(errors).to be_nil }
    end
  end

  describe '#notifications_for_dossier' do
    let!(:dossier) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }

    subject { instructeur.notifications_for_dossier(dossier) }

    context 'when the instructeur has just followed the dossier' do
      it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on private champs' do
      before { dossier.champs_private.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: false, annotations_privees: true, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on avis' do
      before { create(:avis, dossier: dossier) }

      it { is_expected.to match({ demande: false, annotations_privees: false, avis: true, messagerie: false }) }
    end

    context 'messagerie' do
      context 'when there is a new commentaire' do
        before { create(:commentaire, dossier: dossier, email: 'a@b.com') }

        it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: true }) }
      end

      context 'when there is a new commentaire issued by tps' do
        before { create(:commentaire, dossier: dossier, email: CONTACT_EMAIL) }

        it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
      end
    end
  end

  describe '#notifications_for_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let(:procedure) { dossier.procedure }
    let!(:instructeur_2) { create(:instructeur, groupe_instructeurs: [procedure.defaut_groupe_instructeur]) }

    let!(:dossier_on_procedure_2) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let!(:instructeur_on_procedure_2) { dossier_on_procedure_2.follows.first.instructeur }

    before do
      instructeur_2.followed_dossiers << dossier
    end

    subject { instructeur.notifications_for_procedure(procedure) }

    context 'when the instructeur has just followed the dossier' do
      it { is_expected.to match([]) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match([dossier.id]) }
      it { expect(instructeur_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      it { expect(instructeur_on_procedure_2.notifications_for_procedure(procedure)).to match([]) }

      context 'and there is a modification on private champs' do
        before { dossier.champs_private.first.update_attribute('value', 'toto') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when instructeur update it s public champs last seen' do
        let(:follow) { instructeur.follows.find_by(dossier: dossier) }

        before { follow.update_attribute('demande_seen_at', Time.zone.now) }

        it { is_expected.to match([]) }
        it { expect(instructeur_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      end
    end

    context 'when there is a modification on public champs on a followed dossier from another procedure' do
      before { dossier_on_procedure_2.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match([]) }
    end

    context 'when there is a modification on private champs' do
      before { dossier.champs_private.first.update_attribute('value', 'toto') }

      it { is_expected.to match([dossier.id]) }
    end

    context 'when there is a modification on avis' do
      before { create(:avis, dossier: dossier) }

      it { is_expected.to match([dossier.id]) }
    end

    context 'the messagerie' do
      context 'when there is a new commentaire' do
        before { create(:commentaire, dossier: dossier, email: 'a@b.com') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when there is a new commentaire issued by tps' do
        before { create(:commentaire, dossier: dossier, email: CONTACT_EMAIL) }

        it { is_expected.to match([]) }
      end
    end
  end

  describe '#notifications_per_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let(:procedure) { dossier.procedure }

    subject { instructeur.notifications_per_procedure }

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ procedure.id => 1 }) }
    end
  end

  describe '#mark_tab_as_seen' do
    let!(:dossier) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let(:freeze_date) { Time.zone.parse('12/12/2012') }

    context 'when demande is acknowledged' do
      let(:follow) { instructeur.follows.find_by(dossier: dossier) }

      before do
        Timecop.freeze(freeze_date)
        instructeur.mark_tab_as_seen(dossier, :demande)
      end
      after { Timecop.return }

      it { expect(follow.demande_seen_at).to eq(freeze_date) }
    end
  end

  describe '#young_login_token?' do
    let!(:instructeur) { create(:instructeur) }

    context 'when there is a token' do
      let!(:good_token) { instructeur.create_trusted_device_token }

      context 'when the token has just been created' do
        it { expect(instructeur.young_login_token?).to be true }
      end

      context 'when the token is a bit old' do
        before { instructeur.trusted_device_tokens.first.update(created_at: (TrustedDeviceToken::LOGIN_TOKEN_YOUTH + 1.minute).ago) }
        it { expect(instructeur.young_login_token?).to be false }
      end
    end

    context 'when there are no token' do
      it { expect(instructeur.young_login_token?).to be_falsey }
    end
  end

  describe '#email_notification_data' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure_to_assign) { create(:procedure) }

    before do
      create(:assign_to, instructeur: instructeur, procedure: procedure_to_assign, email_notifications_enabled: true, groupe_instructeur: procedure_to_assign.defaut_groupe_instructeur)
    end

    context 'when a dossier in construction exists' do
      let!(:dossier) { create(:dossier, procedure: procedure_to_assign, state: Dossier.states.fetch(:en_construction)) }

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 1,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle
          }
        ])
      end
    end

    context 'when a notification exists' do
      before do
        allow(instructeur).to receive(:notifications_for_procedure)
          .with(procedure_to_assign, :all)
          .and_return([1, 2, 3])
      end

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_notification: 3,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle
          }
        ])
      end
    end

    context 'otherwise' do
      it { expect(instructeur.email_notification_data).to eq([]) }
    end
  end

  private

  def assign(procedure_to_assign)
    create :assign_to, instructeur: instructeur, procedure: procedure_to_assign, groupe_instructeur: procedure_to_assign.defaut_groupe_instructeur
  end
end
