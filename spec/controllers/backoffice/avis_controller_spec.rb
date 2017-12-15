require 'spec_helper'

describe Backoffice::AvisController, type: :controller do
  describe '#POST create' do
    let(:claimant){ create(:gestionnaire) }
    let(:gestionnaire){ create(:gestionnaire) }
    let!(:dossier) do
      dossier = create(:dossier, state: 'en_instruction')
      claimant.procedures << [dossier.procedure]
      dossier
    end

    subject do
      post :create, params: { dossier_id: dossier.id, avis: { email: gestionnaire.email, introduction: "Bonjour, regardez ce joli dossier." } }
    end

    context 'when gestionnaire is not authenticated' do
      before { subject }

      it { expect(response).to redirect_to new_user_session_path }
      it { expect(Avis.count).to eq(0) }
    end

    context 'when gestionnaire is authenticated' do
      let(:created_avis) { Avis.last }

      before do
        sign_in claimant
        subject
      end

      it { expect(response).to redirect_to backoffice_dossier_path(dossier.id) }
      it { expect(Avis.count).to eq(1) }
      it { expect(created_avis.dossier_id).to eq(dossier.id) }
      it { expect(created_avis.gestionnaire).to eq(gestionnaire) }
      it { expect(created_avis.claimant).to eq(claimant) }
      it { expect(created_avis.confidentiel).to be(true) }
    end
  end

  describe '#POST update' do
    let(:gestionnaire){ create(:gestionnaire) }
    let(:dossier){ create(:dossier, state: 'en_instruction') }
    let(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire )}

    subject { post :update, params: { dossier_id: dossier.id, id: avis.id, avis: { answer: "Ok ce dossier est valide." } } }

    before :each do
      notification = double('notification', notify: true)
      allow(NotificationService).to receive(:new).and_return(notification)
    end

    context 'when gestionnaire is not authenticated' do
      it { is_expected.to redirect_to new_user_session_path }
      it { expect(avis.answer).to be_nil }
    end

    context 'when gestionnaire is authenticated' do
      before do
        sign_in gestionnaire
      end

      context 'and is invited on dossier' do
        it { is_expected.to redirect_to backoffice_dossier_path(dossier.id) }
        it do
          subject
          expect(avis.reload.answer).to eq("Ok ce dossier est valide.")
          expect(NotificationService).to have_received(:new).at_least(:once)
        end
      end

      context 'but is not invited on dossier' do
        let(:gestionnaire2) { create(:gestionnaire) }
        let(:avis){ create(:avis, dossier: dossier, gestionnaire: gestionnaire2 )}

        it { expect{ subject }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end
  end

  describe '.sign_up' do
    let(:invited_email) { 'invited@avis.com' }
    let(:dossier) { create(:dossier) }
    let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
    let(:invitations_email) { true }

    context 'when the new gestionnaire has never signed up' do
      before do
        expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
          .with(avis.id.to_s, invited_email)
          .and_return(invitations_email)
        get :sign_up, params: { id: avis.id, email: invited_email }
      end

      context 'when the email belongs to the invitation' do
        it { expect(subject.status).to eq(200) }
        it { expect(assigns(:email)).to eq(invited_email) }
        it { expect(assigns(:dossier)).to eq(dossier) }
      end

      context 'when the email does not belong to the invitation' do
        let(:invitations_email) { false }

        it { is_expected.to redirect_to root_path }
      end
    end

    context 'when the gestionnaire has already signed up and belongs to the invitation' do
      let(:gestionnaire) { create(:gestionnaire, email: invited_email) }
      let!(:avis) { create(:avis, dossier: dossier, gestionnaire: gestionnaire) }

      context 'when the gestionnaire is authenticated' do
        before do
          sign_in gestionnaire
          get :sign_up, params: { id: avis.id, email: invited_email }
        end

        it { is_expected.to redirect_to backoffice_dossier_url(avis.dossier) }
      end

      context 'when the gestionnaire is not authenticated' do
        before do
          get :sign_up, params: { id: avis.id, email: invited_email }
        end

        it { is_expected.to redirect_to new_gestionnaire_session_url }
      end
    end

    context 'when the gestionnaire has already signed up / is authenticated and does not belong to the invitation' do
      let(:gestionnaire) { create(:gestionnaire, email: 'other@gmail.com') }
      let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }

      before do
        sign_in gestionnaire
        get :sign_up, params: { id: avis.id, email: invited_email }
      end

      # redirected to dossier but then the gestionnaire gonna be banished !
      it { is_expected.to redirect_to backoffice_dossier_url(avis.dossier) }
    end
  end

  describe '.create_gestionnaire' do
    let(:invited_email) { 'invited@avis.com' }
    let(:dossier) { create(:dossier) }
    let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
    let(:avis_id) { avis.id }
    let(:password) { '12345678' }
    let(:created_gestionnaire) { Gestionnaire.find_by(email: invited_email) }
    let(:invitations_email) { true }

    before do
      allow(Avis).to receive(:link_avis_to_gestionnaire)
      expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
        .with(avis_id.to_s, invited_email)
        .and_return(invitations_email)

      post :create_gestionnaire, params: { id: avis_id,
                                           email: invited_email,
                                           gestionnaire: {
                                             password: password
                                           } }
    end

    context 'when the email does not belong to the invitation' do
      let(:invitations_email) { false }

      it { is_expected.to redirect_to root_path }
    end

    context 'when the email belongs to the invitation' do
      context 'when the gestionnaire creation succeeds' do
        it { expect(created_gestionnaire).to be_present }
        it { expect(created_gestionnaire.valid_password?(password)).to be true }

        it { expect(Avis).to have_received(:link_avis_to_gestionnaire) }

        it { expect(subject.current_gestionnaire).to eq(created_gestionnaire) }
        it { is_expected.to redirect_to backoffice_dossier_path(dossier) }
      end

      context 'when the gestionnaire creation fails' do
        let(:password) { '' }

        it { expect(created_gestionnaire).to be_nil }
        it { is_expected.to redirect_to avis_sign_up_path(avis_id, invited_email) }
        it { expect(flash.alert).to eq(['Password : Le mot de passe est vide']) }
      end
    end
  end
end
