require 'spec_helper'

describe Gestionnaire, type: :model do
  let(:admin) { create :administrateur }
  let!(:procedure) { create :procedure, administrateur: admin }
  let!(:procedure_2) { create :procedure, administrateur: admin }
  let!(:procedure_3) { create :procedure, administrateur: admin }
  let(:gestionnaire) { create :gestionnaire, procedure_filter: procedure_filter, administrateurs: [admin] }
  let(:procedure_filter) { nil }
  let!(:procedure_assign) { create :assign_to, gestionnaire: gestionnaire, procedure: procedure }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_2
  end

  describe 'database column' do
    it { is_expected.to have_db_column(:email) }
    it { is_expected.to have_db_column(:encrypted_password) }
    it { is_expected.to have_db_column(:reset_password_token) }
    it { is_expected.to have_db_column(:reset_password_sent_at) }
    it { is_expected.to have_db_column(:remember_created_at) }
    it { is_expected.to have_db_column(:sign_in_count) }
    it { is_expected.to have_db_column(:current_sign_in_at) }
    it { is_expected.to have_db_column(:last_sign_in_at) }
    it { is_expected.to have_db_column(:current_sign_in_ip) }
    it { is_expected.to have_db_column(:last_sign_in_ip) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
  end

  describe 'association' do
    it { is_expected.to have_one(:preference_smart_listing_page) }
    it { is_expected.to have_and_belong_to_many(:administrateurs) }
    it { is_expected.to have_many(:procedures) }
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to have_many(:follows) }
    it { is_expected.to have_many(:preference_list_dossiers) }
  end

  describe '#toggle_follow_dossier' do
    let!(:dossier) { create :dossier, procedure: procedure }

    subject { gestionnaire.toggle_follow_dossier dossier_id }

    context 'when dossier id not valid' do
      let(:dossier_id) { 0 }

      it { expect(subject).to eq nil }
    end

    context 'when dossier id is valid' do
      let(:dossier_id) { dossier.id }

      context 'when dossier is not follow by gestionnaire' do
        it 'value change in database' do
          expect { subject }.to change(Follow, :count).by(1)
        end

        it { expect(subject).to be_an_instance_of Follow }
      end

      context 'when dossier is follow by gestionnaire' do
        before do
          create :follow, dossier_id: dossier.id, gestionnaire_id: gestionnaire.id
        end

        it 'value change in database' do
          expect { subject }.to change(Follow, :count).by(-1)
        end

        it { expect(subject).to eq 1 }
      end
    end

    context 'when dossier instance is past' do
      let(:dossier_id) { dossier }

      context 'when dossier is not follow by gestionnaire' do
        it 'value change in database' do
          expect { subject }.to change(Follow, :count).by(1)
        end

        it { expect(subject).to be_an_instance_of Follow }
      end

      context 'when dossier is follow by gestionnaire' do
        before do
          create :follow, dossier_id: dossier.id, gestionnaire_id: gestionnaire.id
        end

        it 'value change in database' do
          expect { subject }.to change(Follow, :count).by(-1)
        end

        it { expect(subject).to eq 1 }
      end
    end
  end

  describe '#follow?' do
    let!(:dossier) { create :dossier, procedure: procedure }

    subject { gestionnaire.follow? dossier.id }

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
      subject }
    end

    context 'when gestionnaire follow any dossier into the procedure past in params' do
      before do
        create :follow, gestionnaire: gestionnaire, dossier: create(:dossier, procedure: procedure_2)
      end

      it { is_expected.to eq 0 }
      it { expect(gestionnaire.follows.count).to eq 1 }
      it { expect_any_instance_of(Dossier::ActiveRecord_AssociationRelation).not_to receive(:inject)
      subject }
    end

    context 'when gestionnaire follow a dossier with a notification into the procedure past in params' do
      let(:dossier) { create(:dossier, procedure: procedure, state: 'initiated') }

      before do
        create :follow, gestionnaire: gestionnaire, dossier: dossier
        create :notification, dossier: dossier
      end

      it { is_expected.to eq 1 }
      it { expect(gestionnaire.follows.count).to eq 1 }
      it { expect_any_instance_of(Dossier::ActiveRecord_AssociationRelation).to receive(:inject)
      subject }
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
end
