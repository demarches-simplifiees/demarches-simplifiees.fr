require 'rails_helper'

describe Gestionnaire, type: :model do
  let(:admin) { create :administrateur }
  let!(:procedure) { create :procedure, administrateur: admin }
  let!(:procedure_2) { create :procedure, administrateur: admin }
  let(:gestionnaire) { create :gestionnaire, procedure_filter: procedure_filter, administrateurs: [admin] }
  let(:procedure_filter) { [] }

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
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

  describe '#dossiers_follow' do
    let!(:dossier) { create :dossier, procedure: procedure }

    before do
      create :follow, dossier_id: dossier.id, gestionnaire_id: gestionnaire.id
    end

    subject { gestionnaire.dossiers_follow }

    it { expect(Follow.all.size).to eq 1 }
    it { expect(subject.first).to eq dossier }
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
end
