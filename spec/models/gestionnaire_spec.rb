require 'spec_helper'

describe Gestionnaire, type: :model do
  let(:admin) { create :administrateur }
  let!(:procedure) { create :procedure, :published, administrateur: admin }
  let!(:procedure_2) { create :procedure, :published, administrateur: admin }
  let!(:procedure_3) { create :procedure, :published, administrateur: admin }
  let(:gestionnaire) { create :gestionnaire, procedure_filter: procedure_filter, administrateurs: [admin] }
  let(:procedure_filter) { nil }
  let!(:procedure_assign) { create :assign_to, gestionnaire: gestionnaire, procedure: procedure }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2
  end

  describe 'follow' do
    let(:dossier) { create :dossier }
    let(:already_followed_dossier) { create :dossier }

    before { gestionnaire.followed_dossiers << already_followed_dossier }

    context 'when a gestionnaire follow a dossier for the first time' do
      before { gestionnaire.follow(dossier) }

      it { expect(gestionnaire.follow?(dossier)).to be true }
    end

    context 'when a gestionnaire follows a dossier already followed' do
      before { gestionnaire.follow(already_followed_dossier) }

      it { expect(gestionnaire.follow?(already_followed_dossier)).to be true }
    end
  end

  describe '#unfollow' do
    let(:already_followed_dossier) { create(:dossier) }
    before { gestionnaire.followed_dossiers << already_followed_dossier }

    context 'when a gestionnaire unfollow a dossier already followed' do
      before do
        gestionnaire.unfollow(already_followed_dossier)
        already_followed_dossier.reload
      end

      it { expect(gestionnaire.follow?(already_followed_dossier)).to be false }
    end
  end

  describe '#follow?' do
    let!(:dossier) { create :dossier, procedure: procedure }

    subject { gestionnaire.follow?(dossier) }

    context 'when gestionnaire follow a dossier' do
      before do
        create :follow, dossier_id: dossier.id, gestionnaire_id: gestionnaire.id
      end

      it { is_expected.to be_truthy }
    end

    context 'when gestionnaire not follow a dossier' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#build_default_preferences_list_dossier' do
    subject { gestionnaire.preference_list_dossiers }

    context 'when gestionnaire is created' do
      it 'build default 5 pref list dossier object' do
        expect(subject.size).to eq 5
      end

      it 'build dossier_id column' do
        expect(subject.first.table).to be_nil
        expect(subject.first.attr).to eq 'id'
      end

      it 'build dossier state column' do
        expect(subject[1].table).to be_nil
        expect(subject[1].attr).to eq 'state'
      end

      it 'build procedure libelle column' do
        expect(subject[2].table).to eq 'procedure'
        expect(subject[2].attr).to eq 'libelle'
      end

      it 'build entreprise raison_sociale column' do
        expect(subject[3].table).to eq 'entreprise'
        expect(subject[3].attr).to eq 'raison_sociale'
      end

      it 'build entreprise raison_sociale column' do
        expect(subject.last.table).to eq 'etablissement'
        expect(subject.last.attr).to eq 'siret'
      end
    end
  end

  describe '#build_default_preferences_smart_listing_page' do
    subject { gestionnaire.preference_smart_listing_page }

    context 'when gestionnaire is created' do
      it 'build page column' do
        expect(subject.page).to eq 1
      end

      it 'build liste column' do
        expect(subject.liste).to eq 'a_traiter'
      end

      it 'build procedure_id column' do
        expect(subject.procedure).to eq nil
      end

      it 'build gestionnaire column' do
        expect(subject.gestionnaire).to eq gestionnaire
      end
    end
  end

  context 'unified login' do
    it 'syncs credentials to associated user' do
      gestionnaire = create(:gestionnaire)
      user = create(:user, email: gestionnaire.email)

      gestionnaire.update_attributes(email: 'whoami@plop.com', password: 'super secret')

      user.reload
      expect(user.email).to eq('whoami@plop.com')
      expect(user.valid_password?('super secret')).to be(true)
    end

    it 'syncs credentials to associated administrateur' do
      gestionnaire = create(:gestionnaire)
      admin = create(:administrateur, email: gestionnaire.email)

      gestionnaire.update_attributes(email: 'whoami@plop.com', password: 'super secret')

      admin.reload
      expect(admin.email).to eq('whoami@plop.com')
      expect(admin.valid_password?('super secret')).to be(true)
    end
  end

  describe '#notifications_for' do
    subject { gestionnaire.notifications_for procedure }

    context 'when gestionnaire follow any dossier' do
      it { is_expected.to eq 0 }
      it { expect(gestionnaire.follows.count).to eq 0 }
      it { expect_any_instance_of(Dossier::ActiveRecord_AssociationRelation).not_to receive(:inject)
        subject
      }
    end

    context 'when gestionnaire follow any dossier into the procedure past in params' do
      before do
        create :follow, gestionnaire: gestionnaire, dossier: create(:dossier, procedure: procedure_2)
      end

      it { is_expected.to eq 0 }
      it { expect(gestionnaire.follows.count).to eq 1 }
      it { expect_any_instance_of(Dossier::ActiveRecord_AssociationRelation).not_to receive(:inject)
        subject
      }
    end

    context 'when gestionnaire follow a dossier with a notification into the procedure past in params' do
      let(:dossier) { create(:dossier, procedure: procedure, state: 'en_construction') }

      before do
        create :follow, gestionnaire: gestionnaire, dossier: dossier
        create :notification, dossier: dossier
      end

      it { is_expected.to eq 1 }
      it { expect(gestionnaire.follows.count).to eq 1 }
      it { expect_any_instance_of(Dossier::ActiveRecord_AssociationRelation).to receive(:inject)
        subject
      }
    end
  end

  describe '#procedure_filter' do
    subject { gestionnaire.procedure_filter }

    context 'when procedure_filter_id is nil' do
      it { is_expected.to eq nil }
    end

    context 'when procedure_filter is not nil' do
      context 'when gestionnaire is assign_to the procedure filter id' do
        before do
          gestionnaire.update_column :procedure_filter, procedure.id
        end

        it { expect(AssignTo.where(gestionnaire: gestionnaire, procedure: procedure).count).to eq 1 }
        it { is_expected.to eq procedure_assign.procedure.id }
      end

      context 'when gestionnaire is not any more assign to the procedure filter id' do
        before do
          gestionnaire.update_column :procedure_filter, procedure_3.id
        end

        it { expect(AssignTo.where(gestionnaire: gestionnaire, procedure: procedure_3).count).to eq 0 }
        it { is_expected.to be_nil }
      end

      context "when procedure is hidden clear procedure_filter" do
        before do
          gestionnaire.update_column :procedure_filter, procedure_3.id
          procedure_3.hide!
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#dossiers_with_notifications_count' do
    subject { gestionnaire.dossiers_with_notifications_count }

    context 'when there is no notifications' do
      it { is_expected.to eq(0) }
    end

    context 'when there is one notification for one dossier' do
      let(:notification){ create(:notification, already_read: false) }
      let!(:follow){ create(:follow, dossier: notification.dossier, gestionnaire: gestionnaire) }

      it { is_expected.to eq(1) }
    end

    context 'when there is one notification read' do
      let(:notification){ create(:notification, already_read: true) }
      let!(:follow){ create(:follow, dossier: notification.dossier, gestionnaire: gestionnaire) }

      it { is_expected.to eq(0) }
    end

    context 'when there are many notifications for one dossier' do
      let(:notification){ create(:notification, already_read: false) }
      let(:notification2){ create(:notification, already_read: false, dossier: notification.dossier) }
      let!(:follow){ create(:follow, dossier: notification.dossier, gestionnaire: gestionnaire) }

      it { is_expected.to eq(1) }
    end

    context 'when there are many notifications for many dossiers' do
      let(:notification){ create(:notification, already_read: false) }
      let(:notification2){ create(:notification, already_read: false) }
      let!(:follow){ create(:follow, dossier: notification.dossier, gestionnaire: gestionnaire) }
      let!(:follow2){ create(:follow, dossier: notification2.dossier, gestionnaire: gestionnaire) }

      it { is_expected.to eq(2) }
    end
  end

  describe '#dossiers_with_notifications_count_for_procedure' do
    subject { gestionnaire.dossiers_with_notifications_count_for_procedure(procedure) }

    context 'without notifications' do
      it { is_expected.to eq(0) }
    end

    context 'with a followed dossier' do
      let!(:dossier){create(:dossier, procedure: procedure, state: 'received')}
      let!(:follow){ create(:follow, dossier: dossier, gestionnaire: gestionnaire) }

      context 'with 1 notification' do
        let!(:notification){ create(:notification, already_read: false, dossier: dossier) }

        it { is_expected.to eq(1) }
      end

      context 'with 1 read notification' do
        let!(:notification){ create(:notification, already_read: true, dossier: dossier) }

        it { is_expected.to eq(0) }
      end

      context 'with 2 notifications' do
        let!(:notification){ create(:notification, already_read: false, dossier: dossier) }
        let!(:notification2){ create(:notification, already_read: false, dossier: dossier) }

        it { is_expected.to eq(1) }
      end

      context 'with another dossier' do
        let!(:dossier2){create(:dossier, procedure: procedure, state: 'received')}
        let!(:follow2){ create(:follow, dossier: dossier2, gestionnaire: gestionnaire) }

        context 'and some notifications' do
          let!(:notification){ create(:notification, already_read: false, dossier: dossier) }
          let!(:notification2){ create(:notification, already_read: false, dossier: dossier) }
          let!(:notification3){ create(:notification, already_read: false, dossier: dossier) }

          let!(:notification4){ create(:notification, already_read: false, dossier: dossier2) }
          let!(:notification5){ create(:notification, already_read: false, dossier: dossier2) }

          it { is_expected.to eq(2) }
        end
      end
    end
  end

  describe 'last_week_overview' do
    let!(:gestionnaire2) { create(:gestionnaire) }
    subject { gestionnaire2.last_week_overview }
    let(:friday) { DateTime.new(2017, 5, 12) }
    let(:monday) { DateTime.now.beginning_of_week }

    before { Timecop.freeze(friday) }
    after { Timecop.return }

    context 'when no procedure published was active last week' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: Time.now) }
      context 'when the gestionnaire has no notifications' do
        it { is_expected.to eq(nil) }
      end
    end

    context 'when a procedure published was active' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: Time.now) }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        expect_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { expect(gestionnaire2.last_week_overview[:procedure_overviews]).to match([procedure_overview]) }
    end

    context 'when a procedure not published was active with no notifications' do
      let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire2], libelle: 'procedure', published_at: nil) }
      let(:procedure_overview) { double('procedure_overview', 'had_some_activities?'.to_sym => true) }

      before :each do
        allow_any_instance_of(Procedure).to receive(:procedure_overview).and_return(procedure_overview)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '.can_view_dossier?' do
    subject{ gestionnaire.can_view_dossier?(dossier.id) }

    context 'when gestionnaire is assigned on dossier' do
      let!(:dossier){ create(:dossier, procedure: procedure, state: 'received') }

      it { expect(subject).to be true }
    end

    context 'when gestionnaire is invited on dossier' do
      let(:dossier){ create(:dossier) }
      let!(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire) }

      it { expect(subject).to be true }
    end

    context 'when gestionnaire is neither assigned nor invited on dossier' do
      let(:dossier){ create(:dossier) }

      it { expect(subject).to be false }
    end
  end

  describe '#notifications_count_per_procedure' do
    subject { gestionnaire.notifications_count_per_procedure }

    let(:dossier_with_unread_notification) do
      create(:dossier, notifications: [Notification.create(type_notif: 'champs', already_read: false)])
    end

    let(:dossier_with_no_unread_notification) do
      create(:dossier, notifications: [Notification.create(type_notif: 'champs', already_read: true)])
    end

    before { gestionnaire.followed_dossiers << followed_dossier }

    context 'when a followed dossier has unread notification' do
      let(:followed_dossier) { dossier_with_unread_notification }

      it { is_expected.to eq({ dossier_with_unread_notification.procedure.id => 1 }) }
    end

    context 'when a followed dossier has unread notification' do
      let(:followed_dossier) { dossier_with_no_unread_notification }

      it { is_expected.to eq({ }) }
    end
  end

  describe "procedure_presentation_for_procedure_id" do
    let!(:procedure_assign_2) { create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2 }
    let!(:pp) { ProcedurePresentation.create(assign_to: procedure_assign) }

    it { expect(gestionnaire.procedure_presentation_for_procedure_id(procedure.id)).to eq(pp)}
    it { expect(gestionnaire.procedure_presentation_for_procedure_id(procedure_2.id).persisted?).to be_falsey}
  end

  describe '#notifications_for_dossier' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }

    subject { gestionnaire.notifications_for_dossier(dossier) }

    context 'when the gestionnaire has just followed the dossier' do
      it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ demande: true, annotations_privees: false, avis: false, messagerie: false }) }
    end

    context 'when there is a modification on a piece jusitificative' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

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
        before { create(:commentaire, dossier: dossier, email: 'contact@tps.apientreprise.fr') }

        it { is_expected.to match({ demande: false, annotations_privees: false, avis: false, messagerie: false }) }
      end
    end
  end

  describe '#notification_for_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:procedure) { dossier.procedure }
    let!(:gestionnaire_2) { create(:gestionnaire, procedures: [procedure]) }

    let!(:dossier_on_procedure_2) { create(:dossier, :followed, state: 'en_construction') }
    let!(:gestionnaire_on_procedure_2) { dossier_on_procedure_2.follows.first.gestionnaire }

    before do
      gestionnaire_2.followed_dossiers << dossier
    end

    subject { gestionnaire.notifications_for_procedure(procedure) }

    context 'when the gestionnaire has just followed the dossier' do
      it { is_expected.to match([]) }
    end

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match([dossier.id]) }
      it { expect(gestionnaire_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      it { expect(gestionnaire_on_procedure_2.notifications_for_procedure(procedure)).to match([]) }

      context 'and there is a modification on private champs' do
        before { dossier.champs_private.first.update_attribute('value', 'toto') }

        it { is_expected.to match([dossier.id]) }
      end

      context 'when gestionnaire update it s public champs last seen' do
        let(:follow) { gestionnaire.follows.find_by(dossier: dossier) }

        before { follow.update_attribute('demande_seen_at', DateTime.now) }

        it { is_expected.to match([]) }
        it { expect(gestionnaire_2.notifications_for_procedure(procedure)).to match([dossier.id]) }
      end
    end

    context 'when there is a modification on a piece justificative' do
      before { dossier.pieces_justificatives << create(:piece_justificative, :contrat) }

      it { is_expected.to match([dossier.id]) }
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
        before { create(:commentaire, dossier: dossier, email: 'contact@tps.apientreprise.fr') }

        it { is_expected.to match([]) }
      end
    end
  end

  describe '#notifications_per_procedure' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:procedure) { dossier.procedure }

    subject { gestionnaire.notifications_per_procedure }

    context 'when there is a modification on public champs' do
      before { dossier.champs.first.update_attribute('value', 'toto') }

      it { is_expected.to match({ procedure.id => 1 }) }
    end
  end

  describe '#mark_tab_as_seen' do
    let!(:dossier) { create(:dossier, :followed, state: 'en_construction') }
    let(:gestionnaire) { dossier.follows.first.gestionnaire }
    let(:freeze_date) { DateTime.parse('12/12/2012') }

    context 'when demande is acknowledged' do
      let(:follow) { gestionnaire.follows.find_by(dossier: dossier) }

      before do
        Timecop.freeze(freeze_date)
        gestionnaire.mark_tab_as_seen(dossier, :demande)
      end
      after { Timecop.return }

      it { expect(follow.demande_seen_at).to eq(freeze_date) }
    end
  end
end
