# frozen_string_literal: true

describe Instructeur, type: :model do
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

  describe 'associations' do
    it do
      is_expected.to have_many(:archives)
      is_expected.to have_many(:exports)
      is_expected.to have_and_belong_to_many(:administrateurs)
      is_expected.to have_many(:batch_operations)
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

    context "when a instructeur is the first to follow a dossier" do
      let!(:notification) { create(:dossier_notification, dossier:, instructeur:, notification_type: :dossier_depose) }

      before { instructeur.follow(dossier) }

      it "destroy dossier_depose notification" do
        expect(DossierNotification.exists?(notification.id)).to be_falsey
      end
    end

    context "when a instructeur follow a dossier that has had notifications" do
      let!(:dossier_with_notifications) { create(:dossier, :en_construction, last_champ_updated_at: Time.zone.now, depose_at: Time.zone.yesterday, last_champ_private_updated_at: Time.zone.now) }
      let!(:commentaire) { create(:commentaire, dossier: dossier_with_notifications) }
      let!(:avis_with_answer) { create(:avis, :with_answer, dossier: dossier_with_notifications) }
      let!(:avis_without_answer) { create(:avis, dossier: dossier_with_notifications) }
      let!(:commentaire_correction) { create(:commentaire, dossier: dossier_with_notifications, instructeur:) }
      let!(:correction) { create(:dossier_correction, dossier: dossier_with_notifications, commentaire: commentaire_correction) }

      subject { instructeur.follow(dossier_with_notifications) }

      it "creates all previous notifications for the instructeur" do
        subject

        expect(DossierNotification.count).to eq(6)
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :annotation_instructeur)
        ).to be_truthy
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :message)
        ).to be_truthy
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :dossier_modifie)
        ).to be_truthy
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :avis_externe)
        ).to be_truthy
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :attente_avis)
        ).to be_truthy
        expect(
          DossierNotification.exists?(instructeur:, dossier: dossier_with_notifications, notification_type: :attente_correction)
        ).to be_truthy
      end

      context "when there are only commentaires from the instructeur who starts to follow" do
        before do
          commentaire.update!(instructeur:)
        end

        it "does not create message notification" do
          subject

          expect(DossierNotification.count).to eq(5)

          expect(DossierNotification.pluck(:notification_type)).not_to include('message')
        end
      end
    end
  end

  describe '#unfollow' do
    let(:already_followed_dossier) { create(:dossier, procedure:) }
    before { instructeur.followed_dossiers << already_followed_dossier }

    context 'when a instructeur unfollow a dossier already followed' do
      before do
        instructeur.unfollow(already_followed_dossier)
        already_followed_dossier.reload
      end

      it do
        expect(instructeur.follow?(already_followed_dossier)).to be false
        expect(instructeur.previously_followed_dossiers).to include(already_followed_dossier)
      end
    end

    context "when the instructeur has notifications on the dossier" do
      let!(:notification_with_followed_preference) { create(:dossier_notification, dossier: already_followed_dossier, instructeur:, notification_type: :dossier_modifie) }
      let!(:notification_with_all_preference) { create(:dossier_notification, dossier: already_followed_dossier, instructeur:, notification_type: :message) }
      let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur:, procedure:, display_dossier_modifie_notifications: 'followed', display_message_notifications: 'all') }

      it "destroys only notifications for which the instructeur has an 'followed' preference" do
        instructeur.unfollow(already_followed_dossier)

        expect(DossierNotification.exists?(notification_with_followed_preference.id)).to be_falsey
        expect(DossierNotification.exists?(notification_with_all_preference.id)).to be_truthy
      end
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

  describe 'last_week_overview' do
    let!(:instructeur2) { create(:instructeur) }
    subject { instructeur2.last_week_overview }
    let(:friday) { Time.zone.local(2017, 5, 12) }
    let(:monday) { Time.zone.now.beginning_of_week }

    before { travel_to(friday) }

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

    context 'when a procedure published was active and weekly notifications is disable' do
      let!(:procedure) { create(:procedure, :published, libelle: 'procedure') }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        instructeur2.assign_to_procedure(procedure)
        AssignTo
          .where(instructeur: instructeur2, groupe_instructeur: procedure.groupe_instructeurs.first)
          .update(weekly_email_notifications_enabled: false)
        allow_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { expect(instructeur2.last_week_overview).to be_nil }
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

  describe "procedure_presentation_and_errors_for_procedure_id" do
    let(:procedure_presentation_and_errors) { instructeur.procedure_presentation_and_errors_for_procedure_id(procedure_id) }
    let(:procedure_presentation) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context 'with explicit presentation' do
      let(:procedure_id) { procedure.id }
      let!(:pp) { ProcedurePresentation.create(assign_to: procedure_assign) }

      it do
        expect(procedure_presentation).to eq(pp)
        expect(errors).to be_nil
      end
    end

    context 'with default presentation' do
      let(:procedure_id) { procedure_2.id }

      it do
        expect(procedure_presentation).to be_persisted
        expect(errors).to be_nil
      end
    end
  end

  describe '#mark_tab_as_seen' do
    let!(:dossier) { create(:dossier, :en_construction, :followed) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let(:freeze_date) { Time.zone.parse('12/12/2012') }

    context 'when demande is acknowledged' do
      let(:follow) { instructeur.follows.find_by(dossier: dossier) }

      before do
        travel_to(freeze_date)
        instructeur.mark_tab_as_seen(dossier, :demande)
      end

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
      create(:assign_to, instructeur: instructeur, procedure: procedure_to_assign, daily_email_notifications_enabled: true)
    end

    context 'when a dossier in construction exists' do
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure_to_assign) }

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 1,
            nb_en_instruction: 0,
            nb_accepted: 0,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle,
          },
        ])
      end
    end

    context 'when a notification exists' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure_to_assign) }
      let!(:notification_to_count) { create(:dossier_notification, instructeur:, dossier:, notification_type: :dossier_modifie) }
      let!(:notification_not_count) { create(:dossier_notification, instructeur:, dossier:) }

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 1,
            nb_en_instruction: 0,
            nb_accepted: 0,
            nb_notification: 1,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle,
          },
        ])
      end
    end

    context 'when a declarated dossier in instruction exists' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure_to_assign) }

      before do
        procedure_to_assign.update!(declarative_with_state: "en_instruction")
        dossier.process_declarative!
      end

      it do
        expect(procedure_to_assign.declarative_with_state).to eq("en_instruction")
        expect(dossier.state).to eq("en_instruction")

        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_en_instruction: 1,
            nb_accepted: 0,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle,
          },
        ])
      end
    end

    context 'when a declarated dossier in accepte processed at today exists' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure_to_assign) }

      before do
        procedure_to_assign.update(declarative_with_state: "accepte")
        dossier.process_declarative!
      end

      it do
        expect(procedure_to_assign.declarative_with_state).to eq("accepte")
        expect(dossier.state).to eq("accepte")
        expect(instructeur.email_notification_data).to eq([])
      end
    end

    context 'when a declarated dossier in accepte processed at yesterday exists' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure_to_assign) }

      before do
        procedure_to_assign.update(declarative_with_state: "accepte")
        dossier.process_declarative!
        dossier.traitements.last.update(processed_at: Time.zone.yesterday.beginning_of_day)
      end

      it do
        expect(procedure_to_assign.declarative_with_state).to eq("accepte")
        expect(dossier.state).to eq("accepte")
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_en_instruction: 0,
            nb_accepted: 1,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle,
          },
        ])
      end
    end

    context 'otherwise' do
      it { expect(instructeur.email_notification_data).to eq([]) }
    end
  end

  describe '#procedures' do
    let(:procedure_a) { create(:procedure) }
    let(:instructeur_a) { create(:instructeur, groupe_instructeurs: [procedure_a.defaut_groupe_instructeur]) }

    before do
      gi2 = procedure_a.groupe_instructeurs.create(label: 'gi2')

      instructeur_a.groupe_instructeurs << gi2
    end

    it { expect(instructeur_a.procedures.all.to_ary).to eq([procedure_a]) }
  end

  describe "#can_be_deleted?" do
    subject { instructeur.can_be_deleted? }

    context 'when the instructeur is an administrateur' do
      let!(:administrateur) { administrateurs(:default_admin) }
      let(:instructeur) { administrateur.instructeur }

      it { is_expected.to be false }
    end

    context "when the instructeur's procedures have other instructeurs" do
      let(:instructeur_not_admin) { create(:instructeur) }
      let(:autre_instructeur) { create(:instructeur) }

      it "can be deleted" do
        assign(procedure, instructeur_assigne: instructeur_not_admin)
        assign(procedure, instructeur_assigne: autre_instructeur)
        expect(autre_instructeur.can_be_deleted?).to be_truthy
      end
    end

    context "when the instructeur's procedures is the only one" do
      let(:instructeur_not_admin) { create :instructeur }
      let(:autre_procedure) { create :procedure }
      it "can be deleted" do
        assign(autre_procedure, instructeur_assigne: instructeur_not_admin)
        expect(instructeur_not_admin.can_be_deleted?).to be_falsy
      end
    end
  end

  describe "#dossiers_count_summary" do
    let(:instructeur_2) { create(:instructeur) }
    let(:instructeur_3) { create(:instructeur) }
    let(:procedure) { create(:procedure, instructeurs: [instructeur_2, instructeur_3], procedure_expires_when_termine_enabled: true) }
    let(:gi_1) { procedure.defaut_groupe_instructeur }
    let(:gi_2) { create(:groupe_instructeur, label: '2', procedure: procedure) }
    let(:gi_3) { create(:groupe_instructeur, label: '3', procedure: procedure) }

    subject do
      instructeur_2.dossiers_count_summary([gi_1.id, gi_2.id])
    end

    context "when logged in, and belonging to gi_1, gi_2" do
      before do
        instructeur.groupe_instructeurs << gi_2
      end

      context "without any dossier" do
        it do
          expect(subject['a_suivre']).to eq(0)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(0)
          expect(subject['tous']).to eq(0)
          expect(subject['archives']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end
      end

      context 'with a new brouillon dossier' do
        let!(:brouillon_dossier) { create(:dossier, procedure: procedure) }

        it do
          expect(subject['a_suivre']).to eq(0)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(0)
          expect(subject['tous']).to eq(0)
          expect(subject['archives']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end
      end

      context 'with a new dossier without follower' do
        let!(:new_unfollow_dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        it do
          expect(subject['a_suivre']).to eq(1)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(0)
          expect(subject['tous']).to eq(1)
          expect(subject['archives']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end

        context 'and dossiers without follower on each of the others groups' do
          let!(:new_unfollow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2) }
          let!(:new_unfollow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3) }

          before { subject }

          it do
            expect(subject['a_suivre']).to eq(2)
            expect(subject['tous']).to eq(2)
          end
        end
      end

      context 'with a new dossier with a follower' do
        let!(:new_followed_dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        before do
          instructeur_2.followed_dossiers << new_followed_dossier
        end

        it do
          expect(subject['a_suivre']).to eq(0)
          expect(subject['suivis']).to eq(1)
          expect(subject['traites']).to eq(0)
          expect(subject['tous']).to eq(1)
          expect(subject['archives']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end

        context 'and another one follows the same dossier' do
          before do
            instructeur_3.followed_dossiers << new_followed_dossier
          end

          it do
            expect(subject['a_suivre']).to eq(0)
            expect(subject['suivis']).to eq(1)
            expect(subject['traites']).to eq(0)
            expect(subject['tous']).to eq(1)
            expect(subject['archives']).to eq(0)
            expect(subject['expirant']).to eq(0)
          end
        end

        context 'and dossier with a follower on each of the others groups' do
          let!(:new_follow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2) }
          let!(:new_follow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3) }

          before do
            instructeur_2.followed_dossiers << new_follow_dossier_on_gi_2 << new_follow_dossier_on_gi_3
          end

          # followed dossiers on another groupe should not be displayed
          it do
            expect(subject['suivis']).to eq(2)
            expect(subject['tous']).to eq(2)
          end
        end

        context 'and dossier with a follower is unfollowed' do
          before do
            instructeur_2.unfollow(new_followed_dossier)
          end

          it do
            expect(subject['a_suivre']).to eq(1)
            expect(subject['suivis']).to eq(0)
            expect(subject['tous']).to eq(1)
            expect(subject['expirant']).to eq(0)
          end
        end
      end

      context 'with a termine dossier' do
        let!(:termine_dossier) { create(:dossier, :accepte, procedure: procedure) }

        it do
          expect(subject['a_suivre']).to eq(0)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(1)
          expect(subject['tous']).to eq(1)
          expect(subject['archives']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end

        context 'and terminer dossiers on each of the others groups' do
          let!(:termine_dossier_on_gi_2) { create(:dossier, :accepte, groupe_instructeur: gi_2) }
          let!(:termine_dossier_on_gi_3) { create(:dossier, :accepte, groupe_instructeur: gi_3) }

          before { subject }

          it do
            expect(subject['a_suivre']).to eq(0)
            expect(subject['suivis']).to eq(0)
            expect(subject['traites']).to eq(2)
            expect(subject['tous']).to eq(2)
            expect(subject['archives']).to eq(0)
            expect(subject['expirant']).to eq(0)
          end
        end
      end

      context 'with an archives dossier' do
        let!(:archives_dossier) { create(:dossier, :en_instruction, procedure: procedure, archived: true) }

        it do
          expect(subject['a_suivre']).to eq(0)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(0)
          expect(subject['tous']).to eq(0)
          expect(subject['archives']).to eq(1)
          expect(subject['supprimes']).to eq(0)
          expect(subject['expirant']).to eq(0)
        end

        context 'and terminer dossiers on each of the others groups' do
          let!(:archives_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2, archived: true) }
          let!(:archives_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3, archived: true) }

          it { expect(subject['archives']).to eq(2) }
        end
      end

      context 'with an expirants dossier' do
        let!(:expiring_dossier_termine_deleted) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago, hidden_by_administration_at: 2.days.ago) }
        let!(:expiring_dossier_termine_auto_deleted) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago, hidden_by_expired_at: 2.days.ago) }
        let!(:expiring_dossier_termine) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago) }
        let!(:expiring_dossier_en_construction) { create(:dossier, :en_construction, en_construction_at: 175.days.ago, procedure: procedure) }

        before { procedure.dossiers.each(&:update_expired_at) }

        it do
          expect(subject['a_suivre']).to eq(1)
          expect(subject['suivis']).to eq(0)
          expect(subject['traites']).to eq(1)
          expect(subject['tous']).to eq(2)
          expect(subject['archives']).to eq(0)
          expect(subject['supprimes']).to eq(2)
          expect(subject['expirant']).to eq(2)
        end
      end
    end
  end

  describe '#merge' do
    let(:old_instructeur) { create(:instructeur) }
    let(:new_instructeur) { create(:instructeur) }

    subject { new_instructeur.merge(old_instructeur) }

    context 'when the old instructeur does not exist' do
      let(:old_instructeur) { nil }

      it { expect { subject }.not_to raise_error }
    end

    context 'when an procedure is assigned to the old instructeur' do
      let(:procedure) { create(:procedure) }

      before do
        procedure.defaut_groupe_instructeur.instructeurs << old_instructeur
        subject
      end

      it 'transfers the assignment' do
        expect(new_instructeur.procedures).to match_array(procedure)
      end
    end

    context 'when both instructeurs are assigned to the same procedure' do
      let(:procedure) { create(:procedure) }

      before do
        procedure.defaut_groupe_instructeur.instructeurs << old_instructeur
        procedure.defaut_groupe_instructeur.instructeurs << new_instructeur
        subject
      end

      it 'keeps the assignment' do
        expect(new_instructeur.procedures).to match_array(procedure)
      end
    end

    context 'when a dossier is followed by an old instructeur' do
      let(:dossier) { create(:dossier) }

      before do
        old_instructeur.followed_dossiers << dossier
        subject
      end

      it 'transfers the dossier' do
        expect(new_instructeur.followed_dossiers).to match_array(dossier)
      end
    end

    context 'when both instructeurs follow the same dossier' do
      let(:dossier) { create(:dossier) }

      before do
        old_instructeur.followed_dossiers << dossier
        new_instructeur.followed_dossiers << dossier
        subject
      end

      it 'does not change anything' do
        expect(new_instructeur.followed_dossiers.pluck(:id)).to match_array(dossier.id)
      end
    end

    context 'when the old instructeur is on on admin list' do
      let(:administrateur) { administrateurs(:default_admin) }

      before do
        administrateur.instructeurs << old_instructeur
        subject
      end

      it 'is replaced by the new one' do
        expect(administrateur.reload.instructeurs).to match_array(new_instructeur)
      end
    end

    context 'when both are on the same admin list' do
      let(:administrateur) { administrateurs(:default_admin) }

      before do
        administrateur.instructeurs << old_instructeur
        administrateur.instructeurs << new_instructeur
        subject
      end

      it 'removes the old one' do
        expect(administrateur.reload.instructeurs).to match_array(new_instructeur)
      end
    end

    context 'when old instructeur has avis' do
      let(:avis) { create(:avis, claimant: old_instructeur) }
      before do
        avis
        subject
      end
      it 'reassign avis to new_instructeur' do
        avis.reload
        expect(avis.claimant).to eq(new_instructeur)
      end
    end
  end

  private

  def assign(procedure_to_assign, instructeur_assigne: instructeur)
    create :assign_to, instructeur: instructeur_assigne, procedure: procedure_to_assign, groupe_instructeur: procedure_to_assign.defaut_groupe_instructeur
  end
end
