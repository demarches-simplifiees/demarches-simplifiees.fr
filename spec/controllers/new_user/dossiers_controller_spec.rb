require 'spec_helper'

describe NewUser::DossiersController, type: :controller do
  let(:user) { create(:user) }

  describe 'before_actions' do
    it 'are present' do
      before_actions = NewUser::DossiersController
        ._process_action_callbacks
        .find_all{ |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!, :ensure_ownership_or_invitation!, :forbid_invite_submission!)
    end
  end

  shared_examples_for 'does not redirect nor flash' do
    before { @controller.send(ensure_authorized) }

    it { expect(@controller).not_to have_received(:redirect_to) }
    it { expect(flash.alert).to eq(nil) }
  end

  shared_examples_for 'redirects and flashes' do
    before { @controller.send(ensure_authorized) }

    it { expect(@controller).to have_received(:redirect_to).with(root_path) }
    it { expect(flash.alert).to eq("Vous n'avez pas accès à ce dossier") }
  end

  describe '#ensure_ownership!' do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :ensure_ownership! }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      expect(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user asks for their own dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when a user asks for another dossier' do
      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for a dossier where they were invited' do
      before { create(:invite, dossier: asked_dossier, user: user, type: 'InviteUser') }

      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for another dossier' do
      before { create(:invite, dossier: create(:dossier), user: user, type: 'InviteUser') }

      it_behaves_like 'redirects and flashes'
    end
  end

  describe '#ensure_ownership_or_invitation!' do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :ensure_ownership_or_invitation! }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      expect(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user asks for their own dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when a user asks for another dossier' do
      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for a dossier where they were invited' do
      before { create(:invite, dossier: asked_dossier, user: user, type: 'InviteUser') }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite asks for another dossier' do
      before { create(:invite, dossier: create(:dossier), user: user, type: 'InviteUser') }

      it_behaves_like 'redirects and flashes'
    end
  end

  describe 'attestation' do
    before { sign_in(user) }

    context 'when a dossier has an attestation' do
      let(:fake_pdf) { double(read: 'pdf content') }
      let!(:dossier) { create(:dossier, attestation: Attestation.new, user: user) }

      it 'returns the attestation pdf' do
        allow_any_instance_of(Attestation).to receive(:pdf).and_return(fake_pdf)

        expect(controller).to receive(:send_data)
          .with('pdf content', filename: 'attestation.pdf', type: 'application/pdf') do
            controller.head :ok
          end

        get :attestation, params: { dossier_id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'update_identite' do
    let(:procedure) { create(:procedure, :for_individual) }
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }

    subject { post :update_identite, params: { id: dossier.id, individual: individual_params, dossier: dossier_params } }

    before do
      sign_in(user)
      subject
    end

    context 'with correct individual and dossier params' do
      let(:individual_params) { { gender: 'M', nom: 'Mouse', prenom: 'Mickey' } }
      let(:dossier_params) { { autorisation_donnees: true } }

      it do
        expect(response).to redirect_to(modifier_dossier_path(dossier))
      end

      context 'on a procedure with carto' do
        let(:procedure) { create(:procedure, :for_individual, :with_api_carto) }

        it do
          expect(response).to redirect_to(users_dossier_carte_path(dossier))
        end
      end
    end

    context 'with incorrect individual and dossier params' do
      let(:individual_params) { { gender: '', nom: '', prenom: '' } }
      let(:dossier_params) { { autorisation_donnees: nil } }

      it do
        expect(response).not_to have_http_status(:redirect)
        expect(flash[:alert]).to include("Civilité doit être rempli", "Nom doit être rempli", "Prénom doit être rempli", "Acceptation des CGU doit être coché")
      end
    end
  end

  describe '#modifier' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user, autorisation_donnees: true) }

    subject { get :modifier, params: { id: dossier.id } }

    context 'when autorisation_donnees is checked' do
      it { is_expected.to render_template(:modifier) }
    end

    context 'when autorisation_donnees is not checked' do
      before { dossier.update_columns(autorisation_donnees: false) }

      context 'when the dossier is for personne morale' do
        it { is_expected.to redirect_to(users_dossier_path(dossier)) }
      end

      context 'when the dossier is for an personne physique' do
        before { dossier.procedure.update(for_individual: true) }

        it { is_expected.to redirect_to(identite_dossier_path(dossier)) }
      end
    end
  end

  describe '#edit' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user) }

    it 'returns the edit page' do
      get :modifier, params: { id: dossier.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#update' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user) }
    let(:first_champ) { dossier.champs.first }
    let(:value) { 'beautiful value' }
    let(:submit_payload) do
      {
        id: dossier.id,
        dossier: {
          champs_attributes: {
            id: first_champ.id,
            value: value
          }
        }
      }
    end
    let(:payload) { submit_payload }

    subject { patch :update, params: payload }

    it 'updates the champs' do
      subject

      expect(response).to redirect_to(merci_dossier_path(dossier))
      expect(first_champ.reload.value).to eq('beautiful value')
      expect(dossier.reload.state).to eq('en_construction')
    end

    it 'sends an email only on the first #update' do
      delivery = double
      expect(delivery).to receive(:deliver_now!).with(no_args)

      expect(NotificationMailer).to receive(:send_notification)
        .and_return(delivery)

      subject

      expect(NotificationMailer).not_to receive(:send_notification)

      subject
    end

    context 'when the update fails' do
      before do
        expect_any_instance_of(Dossier).to receive(:update).and_return(false)
        expect_any_instance_of(Dossier).to receive(:errors)
          .and_return(double(full_messages: ['nop']))

        subject
      end

      it { expect(response).to render_template(:modifier) }
      it { expect(flash.alert).to eq(['nop']) }

      it 'does not send an email' do
        expect(NotificationMailer).not_to receive(:send_notification)

        subject
      end
    end

    context 'when the pj service returns an error' do
      before do
        expect(PiecesJustificativesService).to receive(:upload!).and_return(['nop'])

        subject
      end

      it { expect(response).to render_template(:modifier) }
      it { expect(flash.alert).to eq(['nop']) }
    end

    context 'when a mandatory champ is missing' do
      let(:value) { nil }

      before do
        first_champ.type_de_champ.update(mandatory: true, libelle: 'l')
        allow(PiecesJustificativesService).to receive(:missing_pj_error_messages).and_return(['pj'])

        subject
      end

      it { expect(response).to render_template(:modifier) }
      it { expect(flash.alert).to eq(['Le champ l doit être rempli.', 'pj']) }

      context 'and the user saves a draft' do
        let(:payload) { submit_payload.merge(submit_action: 'draft') }

        it { expect(response).to render_template(:modifier) }
        it { expect(flash.notice).to eq('Votre brouillon a bien été sauvegardé.') }
        it { expect(dossier.reload.state).to eq('brouillon') }
      end
    end

    context 'when dossier has no champ' do
      let(:submit_payload) { { id: dossier.id } }

      it 'does not raise any errors' do
        subject

        expect(response).to redirect_to(merci_dossier_path(dossier))
      end
    end

    context 'when the user has an invitation but is not the owner' do
      let(:dossier) { create(:dossier) }
      let!(:invite) { create(:invite, dossier: dossier, user: user, type: 'InviteUser') }

      context 'and the invite saves a draft' do
        let(:payload) { submit_payload.merge(submit_action: 'draft') }

        before do
          first_champ.type_de_champ.update(mandatory: true, libelle: 'l')
          allow(PiecesJustificativesService).to receive(:missing_pj_error_messages).and_return(['pj'])

          subject
        end

        it { expect(response).to render_template(:modifier) }
        it { expect(flash.notice).to eq('Votre brouillon a bien été sauvegardé.') }
        it { expect(dossier.reload.state).to eq('brouillon') }
      end

      context 'and the invite tries to submit the dossier' do
        before { subject }

        it { expect(response).to redirect_to(root_path) }
        it { expect(flash.alert).to eq("Vous n'avez pas accès à ce dossier") }
      end

      context 'and the invite updates a dossier en constructions' do
        before do
          dossier.en_construction!
          subject
        end

        it { expect(first_champ.reload.value).to eq('beautiful value') }
        it { expect(dossier.reload.state).to eq('en_construction') }
        it { expect(response).to redirect_to(users_dossiers_invite_path(invite)) }
      end
    end
  end

  describe '#index' do
    before { sign_in(user) }

    context 'when the user does not have any dossiers' do
      before { get(:index) }

      it { expect(assigns(:current_tab)).to eq('mes-dossiers') }
    end

    context 'when the user only have its own dossiers' do
      let!(:own_dossier) { create(:dossier, user: user) }

      before { get(:index) }

      it { expect(assigns(:current_tab)).to eq('mes-dossiers') }
      it { expect(assigns(:dossiers)).to match([own_dossier]) }
    end

    context 'when the user only have some dossiers invites' do
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user, type: 'InviteUser') }

      before { get(:index) }

      it { expect(assigns(:current_tab)).to eq('dossiers-invites') }
      it { expect(assigns(:dossiers)).to match([invite.dossier]) }
    end

    context 'when the user has both' do
      let!(:own_dossier) { create(:dossier, user: user) }
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user, type: 'InviteUser') }

      context 'and there is no current_tab param' do
        before { get(:index) }

        it { expect(assigns(:current_tab)).to eq('mes-dossiers') }
      end

      context 'and there is "dossiers-invites" param' do
        before { get(:index, params: { current_tab: 'dossiers-invites' }) }

        it { expect(assigns(:current_tab)).to eq('dossiers-invites') }
      end

      context 'and there is "mes-dossiers" param' do
        before { get(:index, params: { current_tab: 'mes-dossiers' }) }

        it { expect(assigns(:current_tab)).to eq('mes-dossiers') }
      end
    end
  end
end
