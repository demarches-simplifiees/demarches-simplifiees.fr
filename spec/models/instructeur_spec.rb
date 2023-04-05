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
    it { is_expected.to have_and_belong_to_many(:administrateurs) }
    it { is_expected.to have_many(:batch_operations) }
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

      it { expect(procedure_presentation).to eq(pp) }
      it { expect(errors).to be_nil }
    end

    context 'with invalid presentation' do
      let(:procedure_id) { procedure.id }
      before do
        pp = ProcedurePresentation.create(assign_to: procedure_assign, displayed_fields: [{ 'table' => 'invalid', 'column' => 'random' }])
        pp.save(:validate => false)
      end

      it 'recreates a valid prsentation' do
        expect(procedure_presentation).to be_persisted
      end
      it { expect(procedure_presentation).to be_valid }
      it { expect(errors).to be_present }
    end

    context 'with default presentation' do
      let(:procedure_id) { procedure_2.id }

      it { expect(procedure_presentation).to be_persisted }
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
      before { dossier.champs_public.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on identity' do
      before { dossier.update(identity_updated_at: Time.zone.now) }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on groupe instructeur' do
      let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [instructeur], procedure: dossier.procedure) }
      before { dossier.assign_to_groupe_instructeur(groupe_instructeur) }

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

  describe '#notifications_for_groupe_instructeurs' do
    # a procedure, one group, 2 instructeurs
    let(:procedure) { create(:simple_procedure, :routee, :with_type_de_champ_private, :for_individual) }
    let(:gi_p1) { procedure.groupe_instructeurs.last }
    let!(:dossier) { create(:dossier, :with_individual, :followed, procedure: procedure, groupe_instructeur: gi_p1, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let!(:instructeur_2) { create(:instructeur, groupe_instructeurs: [gi_p1]) }

    # another procedure, dossier followed by a third instructeur
    let!(:dossier_on_procedure_2) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let!(:instructeur_on_procedure_2) { dossier_on_procedure_2.follows.first.instructeur }
    let(:gi_p2) { dossier.groupe_instructeur }

    let(:now) { Time.zone.parse("14/09/1867") }
    let(:follow) { instructeur.follows.find_by(dossier: dossier) }
    let(:follow2) { instructeur_2.follows.find_by(dossier: dossier) }

    let(:seen_at_instructeur) { now - 1.hour }
    let(:seen_at_instructeur2) { now - 1.hour }

    before do
      gi_p1.instructeurs << instructeur
      instructeur_2.followed_dossiers << dossier
      Timecop.freeze(now)
    end

    after { Timecop.return }

    subject { instructeur.notifications_for_groupe_instructeurs(gi_p1)[:en_cours] }

    context 'when the instructeur has just followed the dossier' do
      it { is_expected.to match([]) }
    end

    context 'when there is a modification on public champs' do
      before do
        dossier.update!(last_champ_updated_at: now)
        follow.update_attribute('demande_seen_at', seen_at_instructeur)
        follow2.update_attribute('demande_seen_at', seen_at_instructeur2)
      end

      it { is_expected.to match([dossier.id]) }
      it { expect(instructeur_2.notifications_for_groupe_instructeurs(gi_p1)[:en_cours]).to match([dossier.id]) }
      it { expect(instructeur_on_procedure_2.notifications_for_groupe_instructeurs(gi_p2)[:en_cours]).to match([]) }

      context 'and there is a modification on private champs' do
        before { dossier.champs_private.first.update_attribute('value', 'toto') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when instructeur update it s public champs last seen' do
        let(:seen_at_instructeur) { now + 1.hour }
        let(:seen_at_instructeur2) { now - 1.hour }

        it { is_expected.to match([]) }
        it { expect(instructeur_2.notifications_for_groupe_instructeurs(gi_p1)[:en_cours]).to match([dossier.id]) }
      end
    end

    context 'when there is a modification on public champs on a followed dossier from another procedure' do
      before { dossier_on_procedure_2.champs_public.first.update_attribute('value', 'toto') }

      it { is_expected.to match([]) }
    end

    context 'when there is a modification on private champs' do
      before do
        dossier.update!(last_champ_private_updated_at: now)
        follow.update_attribute('annotations_privees_seen_at', seen_at_instructeur)
      end

      it { is_expected.to match([dossier.id]) }
    end

    context 'when there is a modification on avis' do
      before do
        dossier.update!(last_avis_updated_at: Time.zone.now)
        follow.update_attribute('avis_seen_at', seen_at_instructeur)
      end

      it { is_expected.to match([dossier.id]) }
    end

    context 'the identity' do
      context 'when there is a modification on the identity' do
        before do
          dossier.update!(identity_updated_at: Time.zone.now)
          follow.update_attribute('demande_seen_at', seen_at_instructeur)
        end

        it { is_expected.to match([dossier.id]) }
      end
    end

    context 'the messagerie' do
      context 'when there is a new commentaire' do
        before do
          dossier.update!(last_commentaire_updated_at: Time.zone.now)
          follow.update_attribute('messagerie_seen_at', seen_at_instructeur)
        end

        it { is_expected.to match([dossier.id]) }
      end

      context 'when there is a new commentaire issued by tps' do
        before { create(:commentaire, dossier: dossier, email: CONTACT_EMAIL) }

        it { is_expected.to match([]) }
      end
    end
  end

  describe '#procedure_ids_with_notifications' do
    let!(:dossier) { create(:dossier, :followed, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { dossier.follows.first.instructeur }
    let(:procedure) { dossier.procedure }

    subject { instructeur.procedure_ids_with_notifications(:en_cours) }

    context 'when there is a modification on public champs' do
      before { dossier.update!(last_champ_updated_at: Time.zone.now) }

      it { is_expected.to match([procedure.id]) }
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
      create(:assign_to, instructeur: instructeur, procedure: procedure_to_assign, daily_email_notifications_enabled: true)
    end

    context 'when a dossier in construction exists' do
      let!(:dossier) { create(:dossier, procedure: procedure_to_assign, state: Dossier.states.fetch(:en_construction)) }

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 1,
            nb_en_instruction: 0,
            nb_accepted: 0,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle
          }
        ])
      end
    end

    context 'when a notification exists' do
      before do
        allow(instructeur).to receive(:notifications_for_groupe_instructeurs)
          .with([procedure_to_assign.groupe_instructeurs.first.id])
          .and_return(en_cours: [1, 2, 3], termines: [])
      end

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_en_instruction: 0,
            nb_accepted: 0,
            nb_notification: 3,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle
          }
        ])
      end
    end

    context 'when a declarated dossier in instruction exists' do
      let!(:dossier) { create(:dossier, procedure: procedure_to_assign, state: Dossier.states.fetch(:en_construction)) }

      before do
        procedure_to_assign.update(declarative_with_state: "en_instruction")
        Cron::DeclarativeProceduresJob.new.perform
        dossier.reload
      end

      it { expect(procedure_to_assign.declarative_with_state).to eq("en_instruction") }
      it { expect(dossier.state).to eq("en_instruction") }
      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_en_instruction: 1,
            nb_accepted: 0,
            nb_notification: 0,
            procedure_id: procedure_to_assign.id,
            procedure_libelle: procedure_to_assign.libelle
          }
        ])
      end
    end

    context 'when a declarated dossier in accepte processed at today exists' do
      let!(:dossier) { create(:dossier, procedure: procedure_to_assign, state: Dossier.states.fetch(:en_construction)) }

      before do
        procedure_to_assign.update(declarative_with_state: "accepte")
        Cron::DeclarativeProceduresJob.new.perform
        dossier.reload
      end

      it { expect(procedure_to_assign.declarative_with_state).to eq("accepte") }
      it { expect(dossier.state).to eq("accepte") }

      it do
        expect(instructeur.email_notification_data).to eq([])
      end
    end

    context 'when a declarated dossier in accepte processed at yesterday exists' do
      let!(:dossier) { create(:dossier, procedure: procedure_to_assign, state: Dossier.states.fetch(:en_construction)) }

      before do
        procedure_to_assign.update(declarative_with_state: "accepte")
        Cron::DeclarativeProceduresJob.new.perform
        dossier.traitements.last.update(processed_at: Time.zone.yesterday.beginning_of_day)
        dossier.reload
      end

      it { expect(procedure_to_assign.declarative_with_state).to eq("accepte") }
      it { expect(dossier.state).to eq("accepte") }

      it do
        expect(instructeur.email_notification_data).to eq([
          {
            nb_en_construction: 0,
            nb_en_instruction: 0,
            nb_accepted: 1,
            nb_notification: 0,
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
      let!(:administrateur) { create(:administrateur) }
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
    let(:gi_1) { procedure.groupe_instructeurs.first }
    let(:gi_2) { procedure.groupe_instructeurs.create(label: '2') }
    let(:gi_3) { procedure.groupe_instructeurs.create(label: '3') }

    subject do
      instructeur_2.dossiers_count_summary([gi_1.id, gi_2.id])
    end

    context "when logged in, and belonging to gi_1, gi_2" do
      before do
        instructeur.groupe_instructeurs << gi_2
      end

      context "without any dossier" do
        it { expect(subject['a_suivre']).to eq(0) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(0) }
        it { expect(subject['tous']).to eq(0) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(0) }
      end

      context 'with a new brouillon dossier' do
        let!(:brouillon_dossier) { create(:dossier, procedure: procedure) }

        it { expect(subject['a_suivre']).to eq(0) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(0) }
        it { expect(subject['tous']).to eq(0) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(0) }
      end

      context 'with a new dossier without follower' do
        let!(:new_unfollow_dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        it { expect(subject['a_suivre']).to eq(1) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(0) }
        it { expect(subject['tous']).to eq(1) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(0) }

        context 'and dossiers without follower on each of the others groups' do
          let!(:new_unfollow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2) }
          let!(:new_unfollow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3) }

          before { subject }

          it { expect(subject['a_suivre']).to eq(2) }
          it { expect(subject['tous']).to eq(2) }
        end
      end

      context 'with a new dossier with a follower' do
        let!(:new_followed_dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        before do
          instructeur_2.followed_dossiers << new_followed_dossier
        end

        it { expect(subject['a_suivre']).to eq(0) }
        it { expect(subject['suivis']).to eq(1) }
        it { expect(subject['traites']).to eq(0) }
        it { expect(subject['tous']).to eq(1) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(0) }

        context 'and another one follows the same dossier' do
          before do
            instructeur_3.followed_dossiers << new_followed_dossier
          end

          it { expect(subject['a_suivre']).to eq(0) }
          it { expect(subject['suivis']).to eq(1) }
          it { expect(subject['traites']).to eq(0) }
          it { expect(subject['tous']).to eq(1) }
          it { expect(subject['archives']).to eq(0) }
          it { expect(subject['expirant']).to eq(0) }
        end

        context 'and dossier with a follower on each of the others groups' do
          let!(:new_follow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2) }
          let!(:new_follow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3) }

          before do
            instructeur_2.followed_dossiers << new_follow_dossier_on_gi_2 << new_follow_dossier_on_gi_3
          end

          # followed dossiers on another groupe should not be displayed
          it { expect(subject['suivis']).to eq(2) }
          it { expect(subject['tous']).to eq(2) }
        end

        context 'and dossier with a follower is unfollowed' do
          before do
            instructeur_2.unfollow(new_followed_dossier)
          end

          it { expect(subject['a_suivre']).to eq(1) }
          it { expect(subject['suivis']).to eq(0) }
          it { expect(subject['tous']).to eq(1) }
          it { expect(subject['expirant']).to eq(0) }
        end
      end

      context 'with a termine dossier' do
        let!(:termine_dossier) { create(:dossier, :accepte, procedure: procedure) }

        it { expect(subject['a_suivre']).to eq(0) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(1) }
        it { expect(subject['tous']).to eq(1) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(0) }

        context 'and terminer dossiers on each of the others groups' do
          let!(:termine_dossier_on_gi_2) { create(:dossier, :accepte, groupe_instructeur: gi_2) }
          let!(:termine_dossier_on_gi_3) { create(:dossier, :accepte, groupe_instructeur: gi_3) }

          before { subject }

          it { expect(subject['a_suivre']).to eq(0) }
          it { expect(subject['suivis']).to eq(0) }
          it { expect(subject['traites']).to eq(2) }
          it { expect(subject['tous']).to eq(2) }
          it { expect(subject['archives']).to eq(0) }
          it { expect(subject['expirant']).to eq(0) }
        end
      end

      context 'with an archives dossier' do
        let!(:archives_dossier) { create(:dossier, :en_instruction, procedure: procedure, archived: true) }

        it { expect(subject['a_suivre']).to eq(0) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(0) }
        it { expect(subject['tous']).to eq(0) }
        it { expect(subject['archives']).to eq(1) }
        it { expect(subject['expirant']).to eq(0) }

        context 'and terminer dossiers on each of the others groups' do
          let!(:archives_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2, archived: true) }
          let!(:archives_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3, archived: true) }

          it { expect(subject['archives']).to eq(2) }
        end
      end

      context 'with an expirants dossier' do
        let!(:expiring_dossier_termine_deleted) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago, hidden_by_administration_at: 2.days.ago) }
        let!(:expiring_dossier_termine) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago) }
        let!(:expiring_dossier_en_construction) { create(:dossier, :en_construction, en_construction_at: 175.days.ago, procedure: procedure) }
        before { subject }

        it { expect(subject['a_suivre']).to eq(1) }
        it { expect(subject['suivis']).to eq(0) }
        it { expect(subject['traites']).to eq(1) }
        it { expect(subject['tous']).to eq(2) }
        it { expect(subject['archives']).to eq(0) }
        it { expect(subject['expirant']).to eq(2) }
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
      let(:administrateur) { create(:administrateur) }

      before do
        administrateur.instructeurs << old_instructeur
        subject
      end

      it 'is replaced by the new one' do
        expect(administrateur.reload.instructeurs).to match_array(new_instructeur)
      end
    end

    context 'when both are on the same admin list' do
      let(:administrateur) { create(:administrateur) }

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
