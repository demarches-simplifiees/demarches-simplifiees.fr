require 'spec_helper'

describe NewUser::DossiersController, type: :controller do
  let(:user) { create(:user) }

  describe 'before_action: ensure_ownership!' do
    it 'is present' do
      before_actions = NewUser::DossiersController
        ._process_action_callbacks
        .find_all{ |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!)
    end
  end

  describe 'ensure_ownership!' do
    let(:user) { create(:user) }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      expect(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)

      @controller.send(:ensure_ownership!)
    end

    context 'when a user asks for its dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }

      it 'does not redirects nor flash' do
        expect(@controller).not_to have_received(:redirect_to)
        expect(flash.alert).to eq(nil)
      end
    end

    context 'when a user asks for another dossier' do
      let(:asked_dossier) { create(:dossier) }

      it 'redirects and flash' do
        expect(@controller).to have_received(:redirect_to).with(root_path)
        expect(flash.alert).to eq("Vous n'avez pas accès à ce dossier")
      end
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
        expect(response).to redirect_to(users_dossier_description_path(dossier))
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
        before { dossier.procedure.update_attributes(for_individual: true) }

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

      expect(response).to redirect_to(users_dossier_recapitulatif_path(dossier))
      expect(first_champ.reload.value).to eq('beautiful value')
      expect(dossier.reload.state).to eq('en_construction')
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
        first_champ.type_de_champ.update_attributes(mandatory: true, libelle: 'l')
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
  end
end
