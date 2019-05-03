require 'spec_helper'

describe Users::DossiersController, type: :controller do
  let(:user) { create(:user) }

  describe 'before_actions' do
    it 'are present' do
      before_actions = Users::DossiersController
        ._process_action_callbacks
        .find_all { |process_action_callbacks| process_action_callbacks.kind == :before }
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
      before { create(:invite, dossier: asked_dossier, user: user) }

      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for another dossier' do
      before { create(:invite, dossier: create(:dossier), user: user) }

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
      before { create(:invite, dossier: asked_dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite asks for another dossier' do
      before { create(:invite, dossier: create(:dossier), user: user) }

      it_behaves_like 'redirects and flashes'
    end
  end

  describe "#forbid_invite_submission!" do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :forbid_invite_submission! }
    let(:draft) { false }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id, save_draft: draft)
      allow(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user save their own draft' do
      let(:asked_dossier) { create(:dossier, user: user) }
      let(:draft) { true }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when a user submit their own dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }
      let(:draft) { false }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite save the draft for a dossier where they where invited' do
      before { create(:invite, dossier: asked_dossier, user: user) }
      let(:draft) { true }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite submit a dossier where they where invited' do
      before { create(:invite, dossier: asked_dossier, user: user) }
      let(:draft) { false }

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

        get :attestation, params: { id: dossier.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'update_identite' do
    let(:procedure) { create(:procedure, :for_individual) }
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }

    subject { post :update_identite, params: { id: dossier.id, individual: individual_params } }

    before do
      sign_in(user)
      subject
    end

    context 'with correct individual and dossier params' do
      let(:individual_params) { { gender: 'M', nom: 'Mouse', prenom: 'Mickey' } }

      it do
        expect(response).to redirect_to(brouillon_dossier_path(dossier))
      end
    end

    context 'when the identite cannot be updated by the user' do
      let(:dossier) { create(:dossier, :for_individual, :en_instruction, user: user, procedure: procedure) }
      let(:individual_params) { { gender: 'M', nom: 'Mouse', prenom: 'Mickey' } }

      it 'redirects to the dossiers list' do
        expect(response).to redirect_to(dossiers_path)
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'with incorrect individual and dossier params' do
      let(:individual_params) { { gender: '', nom: '', prenom: '' } }

      it do
        expect(response).not_to have_http_status(:redirect)
        expect(flash[:alert]).to include("Civilité doit être rempli", "Nom doit être rempli", "Prénom doit être rempli")
      end
    end
  end

  describe '#siret' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user) }

    subject { get :siret, params: { id: dossier.id } }

    it { is_expected.to render_template(:siret) }
  end

  describe '#update_siret' do
    let(:dossier) { create(:dossier, user: user) }
    let(:siret) { params_siret.delete(' ') }
    let(:siren) { siret[0..8] }

    let(:api_etablissement_status) { 200 }
    let(:api_etablissement_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

    let(:api_entreprise_status) { 200 }
    let(:api_entreprise_body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }

    let(:api_exercices_status) { 200 }
    let(:api_exercices_body) { File.read('spec/fixtures/files/api_entreprise/exercices.json') }

    let(:api_association_status) { 200 }
    let(:api_association_body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

    def stub_api_entreprise_requests
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*token=/)
        .to_return(status: api_etablissement_status, body: api_etablissement_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=/)
        .to_return(status: api_entreprise_status, body: api_entreprise_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/#{siret}?.*token=/)
        .to_return(status: api_exercices_status, body: api_exercices_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/#{siret}?.*token=/)
        .to_return(status: api_association_status, body: api_association_body)
    end

    before do
      sign_in(user)
      stub_api_entreprise_requests
    end

    subject! { post :update_siret, params: { id: dossier.id, user: { siret: params_siret } } }

    shared_examples 'SIRET informations are successfully saved' do
      it do
        dossier.reload
        user.reload

        expect(dossier.etablissement).to be_present
        expect(dossier.autorisation_donnees).to be(true)
        expect(user.siret).to eq(siret)

        expect(response).to redirect_to(etablissement_dossier_path)
      end
    end

    shared_examples 'the request fails with an error' do |error|
      it 'doesn’t save an etablissement' do
        expect(dossier.reload.etablissement).to be_nil
      end

      it 'displays the SIRET that was sent by the user in the form' do
        expect(controller.current_user.siret).to eq(siret)
      end

      it 'renders an error' do
        expect(flash.alert).to eq(error)
        expect(response).to render_template(:siret)
      end
    end

    context 'with an invalid SIRET' do
      let(:params_siret) { '000 000' }

      it_behaves_like 'the request fails with an error', ['Siret Le numéro SIRET doit comporter 14 chiffres']
    end

    context 'with a valid SIRET' do
      let(:params_siret) { '440 117 620 01530' }

      context 'When API-Entreprise is down' do
        let(:api_etablissement_status) { 502 }
        let(:api_body_status) { File.read('spec/fixtures/files/api_entreprise/exercices_unavailable.json') }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_network_error')
      end

      context 'when API-Entreprise doesn’t know this SIRET' do
        let(:api_etablissement_status) { 404 }
        let(:api_body_status) { '' }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_unknown')
      end

      context 'when the API returns no Entreprise' do
        let(:api_entreprise_status) { 404 }
        let(:api_entreprise_body) { '' }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_unknown')
      end

      context 'when the API returns no Exercices' do
        let(:api_exercices_status) { 404 }
        let(:api_exercices_body) { '' }

        it_behaves_like 'SIRET informations are successfully saved'

        it 'doesn’t save the etablissement exercices' do
          expect(dossier.reload.etablissement.exercices).to be_empty
        end
      end

      context 'when the RNA doesn’t have informations on the SIRET' do
        let(:api_association_status) { 404 }
        let(:api_association_body) { '' }

        it_behaves_like 'SIRET informations are successfully saved'

        it 'doesn’t save the RNA informations' do
          expect(dossier.reload.etablissement.association?).to be(false)
        end
      end

      context 'when all API informations available' do
        it_behaves_like 'SIRET informations are successfully saved'

        it 'saves the associated informations on the etablissement' do
          dossier.reload
          expect(dossier.etablissement.entreprise).to be_present
          expect(dossier.etablissement.exercices).to be_present
          expect(dossier.etablissement.association?).to be(true)
        end
      end
    end
  end

  describe '#etablissement' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }

    before { sign_in(user) }

    subject { get :etablissement, params: { id: dossier.id } }

    it { is_expected.to render_template(:etablissement) }

    context 'when the dossier has no etablissement yet' do
      let(:dossier) { create(:dossier, user: user) }
      it { is_expected.to redirect_to siret_dossier_path(dossier) }
    end
  end

  describe '#brouillon' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user, autorisation_donnees: true) }

    subject { get :brouillon, params: { id: dossier.id } }

    context 'when autorisation_donnees is checked' do
      it { is_expected.to render_template(:brouillon) }
    end

    context 'when autorisation_donnees is not checked' do
      before { dossier.update_columns(autorisation_donnees: false) }

      context 'when the dossier is for personne morale' do
        it { is_expected.to redirect_to(siret_dossier_path(dossier)) }
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
      get :brouillon, params: { id: dossier.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#update_brouillon' do
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

    subject { patch :update_brouillon, params: payload }

    context 'when the dossier cannot be updated by the user' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it 'redirects to the dossiers list' do
        subject

        expect(response).to redirect_to(dossiers_path)
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'when dossier can be updated by the owner' do
      it 'updates the champs' do
        subject

        expect(response).to redirect_to(merci_dossier_path(dossier))
        expect(first_champ.reload.value).to eq('beautiful value')
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction))
      end

      context "on an archived procedure" do
        before { dossier.procedure.archive }

        it "it does not change state" do
          subject

          expect(response).not_to redirect_to(merci_dossier_path(dossier))
          expect(dossier.reload.state).to eq(Dossier.states.fetch(:brouillon))
        end
      end
    end

    it 'sends an email only on the first #update_brouillon' do
      delivery = double
      expect(delivery).to receive(:deliver_later).with(no_args)

      expect(NotificationMailer).to receive(:send_initiated_notification)
        .and_return(delivery)

      subject

      expect(NotificationMailer).not_to receive(:send_initiated_notification)

      subject
    end

    context 'when the update fails' do
      before do
        expect_any_instance_of(Dossier).to receive(:save).and_return(false)
        expect_any_instance_of(Dossier).to receive(:errors)
          .and_return(double(full_messages: ['nop']))

        subject
      end

      it { expect(response).to render_template(:brouillon) }
      it { expect(flash.alert).to eq(['nop']) }

      it 'does not send an email' do
        expect(NotificationMailer).not_to receive(:send_initiated_notification)

        subject
      end
    end

    context 'when the pj service returns an error' do
      before do
        expect(PiecesJustificativesService).to receive(:upload!).and_return(['nop'])

        subject
      end

      it { expect(response).to render_template(:brouillon) }
      it { expect(flash.alert).to eq(['nop']) }
    end

    context 'when a mandatory champ is missing' do
      let(:value) { nil }

      before do
        first_champ.type_de_champ.update(mandatory: true, libelle: 'l')
        allow(PiecesJustificativesService).to receive(:missing_pj_error_messages).and_return(['pj'])

        subject
      end

      it { expect(response).to render_template(:brouillon) }
      it { expect(flash.alert).to eq(['Le champ l doit être rempli.', 'pj']) }

      context 'and the user saves a draft' do
        let(:payload) { submit_payload.merge(save_draft: true) }

        it { expect(response).to render_template(:brouillon) }
        it { expect(flash.notice).to eq('Votre brouillon a bien été sauvegardé.') }
        it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:brouillon)) }

        context 'and the dossier is in construction' do
          let!(:dossier) { create(:dossier, :en_construction, user: user) }

          it { expect(response).to render_template(:brouillon) }
          it { expect(flash.alert).to eq(['Le champ l doit être rempli.', 'pj']) }
        end
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
      let!(:invite) { create(:invite, dossier: dossier, user: user) }

      context 'and the invite saves a draft' do
        let(:payload) { submit_payload.merge(save_draft: true) }

        before do
          first_champ.type_de_champ.update(mandatory: true, libelle: 'l')
          allow(PiecesJustificativesService).to receive(:missing_pj_error_messages).and_return(['pj'])

          subject
        end

        it { expect(response).to render_template(:brouillon) }
        it { expect(flash.notice).to eq('Votre brouillon a bien été sauvegardé.') }
        it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:brouillon)) }
      end

      context 'and the invite tries to submit the dossier' do
        before { subject }

        it { expect(response).to redirect_to(root_path) }
        it { expect(flash.alert).to eq("Vous n'avez pas accès à ce dossier") }
      end
    end
  end

  describe '#update' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, :en_construction, user: user) }
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

    context 'when the dossier cannot be updated by the user' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it 'redirects to the dossiers list' do
        subject

        expect(response).to redirect_to(dossiers_path)
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'when dossier can be updated by the owner' do
      it 'updates the champs' do
        subject

        expect(response).to redirect_to(demande_dossier_path(dossier))
        expect(first_champ.reload.value).to eq('beautiful value')
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction))
      end
    end

    context 'when the update fails' do
      before do
        expect_any_instance_of(Dossier).to receive(:save).and_return(false)
        expect_any_instance_of(Dossier).to receive(:errors)
          .and_return(double(full_messages: ['nop']))

        subject
      end

      it { expect(response).to render_template(:modifier) }
      it { expect(flash.alert).to eq(['nop']) }

      it 'does not send an email' do
        expect(NotificationMailer).not_to receive(:send_initiated_notification)

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
    end

    context 'when dossier has no champ' do
      let(:submit_payload) { { id: dossier.id } }

      it 'does not raise any errors' do
        subject

        expect(response).to redirect_to(demande_dossier_path(dossier))
      end
    end

    context 'when the user has an invitation but is not the owner' do
      let(:dossier) { create(:dossier) }
      let!(:invite) { create(:invite, dossier: dossier, user: user) }

      before do
        dossier.en_construction!
        subject
      end

      it { expect(first_champ.reload.value).to eq('beautiful value') }
      it { expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction)) }
      it { expect(response).to redirect_to(demande_dossier_path(dossier)) }
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
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user) }

      before { get(:index) }

      it { expect(assigns(:current_tab)).to eq('dossiers-invites') }
      it { expect(assigns(:dossiers)).to match([invite.dossier]) }
    end

    context 'when the user has both' do
      let!(:own_dossier) { create(:dossier, user: user) }
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user) }

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

    describe 'sort order' do
      before do
        Timecop.freeze(4.days.ago) { create(:dossier, user: user) }
        Timecop.freeze(2.days.ago) { create(:dossier, user: user) }
        Timecop.freeze(4.days.ago) { create(:invite, dossier: create(:dossier), user: user) }
        Timecop.freeze(2.days.ago) { create(:invite, dossier: create(:dossier), user: user) }
        get(:index)
      end

      it 'displays the most recently updated dossiers first' do
        expect(assigns(:user_dossiers).first.updated_at.to_date).to eq(2.days.ago.to_date)
        expect(assigns(:user_dossiers).second.updated_at.to_date).to eq(4.days.ago.to_date)
        expect(assigns(:dossiers_invites).first.updated_at.to_date).to eq(2.days.ago.to_date)
        expect(assigns(:dossiers_invites).second.updated_at.to_date).to eq(4.days.ago.to_date)
      end
    end
  end

  describe '#show' do
    before do
      sign_in(user)
    end

    subject! { get(:show, params: { id: dossier.id }) }

    context 'when the dossier is a brouillon' do
      let(:dossier) { create(:dossier, user: user) }
      it { is_expected.to redirect_to(brouillon_dossier_path(dossier)) }
    end

    context 'when the dossier has been submitted' do
      let(:dossier) { create(:dossier, :en_construction, user: user) }
      it { expect(assigns(:dossier)).to eq(dossier) }
      it { is_expected.to render_template(:show) }
    end
  end

  describe '#formulaire' do
    let(:dossier) { create(:dossier, :en_construction, user: user) }

    before do
      sign_in(user)
    end

    subject! { get(:demande, params: { id: dossier.id }) }

    it { expect(assigns(:dossier)).to eq(dossier) }
    it { is_expected.to render_template(:demande) }
  end

  describe "#create_commentaire" do
    let(:dossier) { create(:dossier, :en_construction, user: user) }
    let(:saved_commentaire) { dossier.commentaires.first }
    let(:body) { "avant\napres" }
    let(:file) { Rack::Test::UploadedFile.new("./spec/fixtures/files/piece_justificative_0.pdf", 'application/pdf') }
    let(:scan_result) { true }

    subject {
      post :create_commentaire, params: {
        id: dossier.id,
        commentaire: {
          body: body,
          file: file
        }
      }
    }

    before do
      sign_in(user)
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
    end

    it "creates a commentaire" do
      expect { subject }.to change(Commentaire, :count).by(1)

      expect(response).to redirect_to(messagerie_dossier_path(dossier))
      expect(flash.notice).to be_present
    end

    context "when the commentaire creation fails" do
      let(:scan_result) { false }

      it "renders the messagerie page with the invalid commentaire" do
        expect { subject }.not_to change(Commentaire, :count)

        expect(response).to render_template :messagerie
        expect(flash.alert).to be_present
        expect(assigns(:commentaire).body).to eq("avant\napres")
      end
    end
  end

  describe '#ask_deletion' do
    before { sign_in(user) }

    subject { post :ask_deletion, params: { id: dossier.id } }

    shared_examples_for "the dossier can not be deleted" do
      it "doesn’t notify the deletion" do
        expect(DossierMailer).not_to receive(:notify_deletion_to_administration)
        expect(DossierMailer).not_to receive(:notify_deletion_to_user)
        subject
      end

      it "doesn’t delete the dossier" do
        subject
        expect(Dossier.find_by(id: dossier.id)).not_to eq(nil)
        expect(dossier.procedure.deleted_dossiers.count).to eq(0)
      end
    end

    context 'when dossier is owned by signed in user' do
      let(:dossier) { create(:dossier, :en_construction, user: user, autorisation_donnees: true) }

      it "notifies the user and the admin of the deletion" do
        expect(DossierMailer).to receive(:notify_deletion_to_administration).with(kind_of(DeletedDossier), dossier.procedure.administrateurs.first.email).and_return(double(deliver_later: nil))
        expect(DossierMailer).to receive(:notify_deletion_to_user).with(kind_of(DeletedDossier), dossier.user.email).and_return(double(deliver_later: nil))
        subject
      end

      it "deletes the dossier" do
        procedure = dossier.procedure
        dossier_id = dossier.id
        subject
        expect(Dossier.find_by(id: dossier_id)).to eq(nil)
        expect(procedure.deleted_dossiers.count).to eq(1)
        expect(procedure.deleted_dossiers.first.dossier_id).to eq(dossier_id)
      end

      it { is_expected.to redirect_to(dossiers_path) }

      context "and the instruction has started" do
        let(:dossier) { create(:dossier, :en_instruction, user: user, autorisation_donnees: true) }

        it_behaves_like "the dossier can not be deleted"
        it { is_expected.to redirect_to(dossier_path(dossier)) }
      end
    end

    context 'when dossier is not owned by signed in user' do
      let(:user2) { create(:user) }
      let(:dossier) { create(:dossier, user: user2, autorisation_donnees: true) }

      it_behaves_like "the dossier can not be deleted"
      it { is_expected.to redirect_to(root_path) }
    end
  end

  describe '#new' do
    let(:procedure) { create(:procedure, :published) }
    let(:procedure_id) { procedure.id }

    subject { get :new, params: { procedure_id: procedure_id } }

    it 'clears the stored procedure context' do
      subject
      expect(controller.stored_location_for(:user)).to be nil
    end

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in user
          end

          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to siret_dossier_path(id: Dossier.last) }

          it { expect { subject }.to change(Dossier, :count).by 1 }

          context 'when procedure is archived' do
            let(:procedure) { create(:procedure, :archived) }

            it { is_expected.to redirect_to dossiers_path }
          end
        end
        context 'when user is not logged' do
          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to new_user_session_path }
        end
      end

      context 'when procedure_id is not valid' do
        let(:procedure_id) { 0 }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to dossiers_path }
      end

      context 'when procedure is not published' do
        let(:procedure) { create(:procedure) }

        before do
          sign_in user
        end

        it { is_expected.to redirect_to dossiers_path }

        context 'and brouillon param is passed' do
          subject { get :new, params: { procedure_id: procedure_id, brouillon: true } }

          it { is_expected.to have_http_status(302) }
          it { is_expected.to redirect_to siret_dossier_path(id: Dossier.last) }
        end
      end
    end
  end

  describe '#purge_champ_piece_justificative' do
    before { sign_in(user) }

    subject { delete :purge_champ_piece_justificative, params: { id: champ.dossier.id, champ_id: champ.id }, format: :js }

    context 'when dossier is owned by user' do
      let(:dossier) { create(:dossier, user: user) }
      let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id) }

      it { is_expected.to have_http_status(200) }

      it do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(false)
      end

      context 'but champ is not linked to this dossier' do
        let(:champ) { create(:champ_piece_justificative, dossier: create(:dossier)) }

        it { is_expected.to redirect_to(root_path) }

        it do
          subject
          expect(champ.reload.piece_justificative_file.attached?).to be(true)
        end
      end
    end

    context 'when dossier is not owned by user' do
      let(:dossier) { create(:dossier, user: create(:user)) }
      let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id) }

      it { is_expected.to redirect_to(root_path) }

      it do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end
    end
  end

  describe "#dossier_for_help" do
    before do
      sign_in(user)
      controller.params[:dossier_id] = dossier_id.to_s
    end

    subject { controller.dossier_for_help }

    context 'when the id matches an existing dossier' do
      let(:dossier) { create(:dossier) }
      let(:dossier_id) { dossier.id }

      it { is_expected.to eq dossier }
    end

    context 'when the id doesn’t match an existing dossier' do
      let(:dossier_id) { 9999999 }
      it { is_expected.to be nil }
    end

    context 'when the id is empty' do
      let(:dossier_id) { nil }
      it { is_expected.to be_falsy }
    end
  end
end
