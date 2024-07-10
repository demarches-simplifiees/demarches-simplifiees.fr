describe Users::DossiersController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  describe 'before_actions' do
    it 'are present' do
      before_actions = Users::DossiersController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
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
    it { expect(flash.alert).to include("Vous n’avez pas accès à ce dossier") }
  end

  describe '#ensure_ownership!' do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :ensure_ownership! }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user asks for their own dossier' do
      before do
        expect(@controller).to receive(:current_user).and_return(user)
      end

      let(:asked_dossier) { create(:dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when a user asks for another dossier' do
      before do
        expect(@controller).to receive(:current_user).twice.and_return(user)
      end

      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for a dossier where they were invited' do
      before do
        expect(@controller).to receive(:current_user).twice.and_return(user)
        create(:invite, dossier: asked_dossier, user: user)
      end

      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for another dossier' do
      before do
        expect(@controller).to receive(:current_user).twice.and_return(user)
        create(:invite, dossier: create(:dossier), user: user)
      end

      it_behaves_like 'redirects and flashes'
    end
  end

  describe '#ensure_ownership_or_invitation!' do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :ensure_ownership_or_invitation! }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user asks for their own dossier' do
      before do
        expect(@controller).to receive(:current_user).and_return(user)
      end

      let(:asked_dossier) { create(:dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when a user asks for another dossier' do
      before do
        expect(@controller).to receive(:current_user).twice.and_return(user)
      end

      it_behaves_like 'redirects and flashes'
    end

    context 'when an invite asks for a dossier where they were invited' do
      before do
        expect(@controller).to receive(:current_user).and_return(user)
        create(:invite, dossier: asked_dossier, user: user)
      end

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite asks for another dossier' do
      before do
        expect(@controller).to receive(:current_user).twice.and_return(user)
        create(:invite, dossier: create(:dossier), user: user)
      end

      it_behaves_like 'redirects and flashes'
    end
  end

  describe "#forbid_invite_submission!" do
    let(:user) { create(:user) }
    let(:asked_dossier) { create(:dossier) }
    let(:ensure_authorized) { :forbid_invite_submission! }

    before do
      @controller.params = @controller.params.merge(dossier_id: asked_dossier.id)
      allow(@controller).to receive(:current_user).and_return(user)
      allow(@controller).to receive(:redirect_to)
    end

    context 'when a user submit their own dossier' do
      let(:asked_dossier) { create(:dossier, user: user) }

      it_behaves_like 'does not redirect nor flash'
    end

    context 'when an invite submit a dossier where they where invited' do
      before { create(:invite, dossier: asked_dossier, user: user) }

      it_behaves_like 'redirects and flashes'
    end
  end

  describe 'attestation' do
    before { sign_in(user) }

    context 'when a dossier has an attestation' do
      let(:dossier) { create(:dossier, :accepte, attestation: create(:attestation, :with_pdf), user: user) }

      it 'redirects to attestation pdf' do
        get :attestation, params: { id: dossier.id }
        expect(response.location).to match '/rails/active_storage/disk/'
      end
    end
  end

  describe '#qrcode' do
    let(:date) { Time.zone.now }
    before {
      Timecop.freeze(Time.zone.local(2018, 1, 2, 23, 11, 14))
      sign_in(user)
    }
    after { Timecop.return }

    context 'when the procedure has an attestation template' do
      let(:another_user) { create(:user) }
      let!(:dossier) { create(:dossier, :with_attestation, user: user) }

      context 'when another user is connected' do
        before { sign_in(another_user) }
        after { sign_in(user) }

        it 'shows attestation as HTML' do
          get :qrcode, params: { id: dossier.id, created_at: dossier.encoded_date(:created_at) }
          expect(response).to render_template(:qrcode)
        end
      end
    end

    context 'when the procedure no longer has an attestation template' do
      let(:another_user) { create(:user) }
      let!(:dossier) { create(:dossier, :with_attestation, user: user) }

      context 'when another user is connected' do
        before { sign_in(another_user) }
        after { sign_in(user) }

        it 'returns error' do
          attestation_template = dossier.attestation_template
          attestation_template.activated = false
          attestation_template.save

          get :qrcode, params: { id: dossier.id, created_at: dossier.encoded_date(:created_at) }
          expect(response.headers["Location"]).to end_with ".pdf"
        end
      end
    end

    context 'when the dossier is no longer accepted' do
      let(:another_user) { create(:user) }
      let!(:dossier) { create(:dossier, :with_attestation, :followed, :accepte, user: user) }
      before { sign_in(user) }

      it 'display error message' do
        dossier.repasser_en_instruction!(instructeur: dossier.followers_instructeurs.first)
        get :qrcode, params: { id: dossier.id, created_at: dossier.encoded_date(:created_at) }
        expect(response).to render_template(:qrcode)
      end
    end
  end

  describe 'update_identite' do
    let(:procedure) { create(:procedure, :for_individual) }
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:now) { Time.zone.parse('01/01/2100') }

    subject { post :update_identite, params: { id: dossier.id, dossier: dossier_params } }

    before do
      sign_in(user)
      Timecop.freeze(now) do
        subject
      end
    end

    context 'with correct individual and dossier params' do
      let(:dossier_params) { { individual_attributes: { gender: 'M', nom: 'Mouse', prenom: 'Mickey' } } }

      it do
        expect(response).to redirect_to(brouillon_dossier_path(dossier))
        expect(dossier.reload.identity_updated_at).to eq(now)
      end
    end

    context 'when the identite cannot be updated by the user' do
      let(:dossier) { create(:dossier, :with_individual, :en_instruction, user: user, procedure: procedure) }
      let(:dossier_params) { { individual_attributes: { gender: 'M', nom: 'Mouse', prenom: 'Mickey' } } }

      it 'redirects to the dossiers list' do
        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'with incorrect individual and dossier params' do
      let(:dossier_params) { { individual_attributes: { gender: '', nom: '', prenom: '' } } }

      it do
        expect(response).not_to have_http_status(:redirect)
        expect(flash[:alert]).to include("Le champ « Civilité » doit être rempli", "Le champ « Nom » doit être rempli", "Le champ « Prénom » doit être rempli")
      end
    end

    context 'when a dossier is in broullon, for_tiers and we want to update the individual' do
      let(:dossier) { create(:dossier, :for_tiers_without_notification, state: "brouillon", user: user, procedure: procedure) }
      let(:dossier_params) { { individual_attributes: { gender: 'M', nom: 'Mouse', prenom: 'Mickey', email: 'mickey@gmail.com', notification_method: 'email' } } }

      it 'updates the individual with valid notification_method' do
        dossier.reload
        individual = dossier.individual.reload
        expect(individual.errors.full_messages).to be_empty
        expect(individual.notification_method).to eq('email')
        expect(individual.email).to eq('mickey@gmail.com')
        expect(response).to redirect_to(brouillon_dossier_path(dossier))
      end

      context 'when we want to change the mandataire' do
        let(:dossier_params) { { mandataire_first_name: "Jean", mandataire_last_name: "Dupont" } }

        it 'updates the dossier mandataire first and last name' do
          dossier.reload
          individual = dossier.individual.reload
          expect(dossier.errors.full_messages).to be_empty
          expect(dossier.mandataire_first_name).to eq('Jean')
          expect(dossier.mandataire_last_name).to eq('Dupont')
          expect(dossier.mandataire_full_name).to eq('Jean Dupont')
        end
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
    let(:api_etablissement_body) { Rails.root.join('spec/fixtures/files/api_entreprise/etablissements.json').read }
    let(:token_expired) { false }
    let(:api_insee_status_response) { nil }

    before do
      sign_in(user)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/etablissements\/#{siret}/)
        .to_return(status: api_etablissement_status, body: api_etablissement_body)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
        .to_return(body: Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read, status: 200)
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles)
        .and_return(["attestations_fiscales", "attestations_sociales", "bilans_entreprise_bdf"])
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(token_expired)

      if api_insee_status_response
        stub_request(:get, "https://entreprise.api.gouv.fr/ping/insee/sirene")
          .to_return(body: api_insee_status_response)
      end

      #----- Pf
      stub_request(:get, Regexp.quote("#{API_ISPF_URL}/etablissements/Entreprise/#{siret}"))
        .to_return(status: api_etablissement_status, body: api_etablissement_body)

      if api_insee_status_response
        has_issues = api_insee_status_response.include?("502") || api_insee_status_response.include?("HASISSUES")
        stub_request(:get, API_ISPF_URL).to_return(status: has_issues ? 502 : 200)
      end
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
      let(:params_siret) { '000 000 00' }

      it_behaves_like 'the request fails with an error', ["Le champ « Siret » " + I18n.t('activemodel.errors.models.siret.attributes.siret.length')]
    end

    context 'with a valid SIRET' do
      let(:params_siret) { '418 166 096 00051' }

      context 'When API-Entreprise is ponctually down' do
        let(:api_etablissement_status) { 502 }
        let(:api_insee_status_response) { Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_network_error')
      end

      context 'When API-Entreprise is globally down' do
        let(:api_etablissement_status) { 502 }
        let(:api_insee_status_response) { Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read.gsub('ok', 'HASISSUES') }

        it "create an etablissement only with SIRET as degraded mode" do
          dossier.reload
          expect(dossier.etablissement.siret).to eq(siret)
          expect(dossier.etablissement).to be_as_degraded_mode
        end
      end

      context 'when API-Entreprise doesn’t know this SIRET' do
        let(:api_etablissement_status) { 404 }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_unknown')
      end

      context 'when default token has expired' do
        let(:api_etablissement_status) { 200 }
        let(:api_insee_status_response) { Rails.root.join('spec/fixtures/files/api_entreprise/ping.json').read }
        let(:token_expired) { true }

        it_behaves_like 'the request fails with an error', I18n.t('errors.messages.siret_network_error')
      end

      context 'when all API informations available' do
        it_behaves_like 'SIRET informations are successfully saved'

        it 'saves the associated informations on the etablissement' do
          dossier.reload
          expect(dossier.etablissement.entreprise).to be_present
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

  describe '#submit_brouillon' do
    before { sign_in(user) }
    let!(:dossier) { create(:dossier, user: user) }
    let(:first_champ) { dossier.champs_public.first }
    let(:anchor_to_first_champ) { controller.helpers.link_to first_champ.libelle, brouillon_dossier_path(anchor: first_champ.labelledby_id), class: 'error-anchor' }
    let(:value) { 'beautiful value' }
    let(:now) { Time.zone.parse('01/01/2100') }
    let(:payload) { { id: dossier.id } }

    subject do
      travel_to now
      post :submit_brouillon, params: payload
    end

    context 'when the dossier cannot be updated by the user' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it 'redirects to the dossiers list' do
        subject

        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    it 'sends an email only on the first #update_brouillon' do
      delivery = double
      expect(delivery).to receive(:deliver_later).with(no_args)

      expect(NotificationMailer).to receive(:send_en_construction_notification)
        .and_return(delivery)

      subject

      expect(NotificationMailer).not_to receive(:send_en_construction_notification)

      subject
    end

    context 'when the update fails' do
      render_views
      let(:error_message) { 'nop' }
      before do
        expect_any_instance_of(Dossier).to receive(:validate).and_return(false)
        expect_any_instance_of(Dossier).to receive(:errors).and_return(
          [double(inner_error: double(base: first_champ), message: 'nop')]
        )
        subject
      end

      it { expect(response).to render_template(:brouillon) }
      it { expect(response.body).to have_link(first_champ.libelle, href: "##{first_champ.labelledby_id}") }
      it { expect(response.body).to have_content(error_message) }

      it 'does not send an email' do
        expect(NotificationMailer).not_to receive(:send_en_construction_notification)

        subject
      end
    end

    context 'when a mandatory champ is missing' do
      render_views

      let(:value) { nil }

      before do
        first_champ.type_de_champ.update(mandatory: true, libelle: 'l')
        subject
      end

      it { expect(response).to render_template(:brouillon) }
      it { expect(response.body).to have_link(first_champ.libelle, href: "##{first_champ.labelledby_id}") }
      it { expect(response.body).to have_content("doit être rempli") }
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

      context 'and the invite tries to submit the dossier' do
        before { subject }

        it { expect(response).to redirect_to(root_path) }
        it { expect(flash.alert).to include("Vous n’avez pas accès à ce dossier") }
      end
    end

    context 'when procedure has sva enabled' do
      let(:procedure) { create(:procedure, :sva) }
      let!(:dossier) { create(:dossier, :brouillon, procedure:, user:) }

      it 'passe automatiquement en instruction' do
        delivery = double.tap { expect(_1).to receive(:deliver_later).with(no_args).twice }
        expect(NotificationMailer).to receive(:send_en_construction_notification).and_return(delivery)
        expect(NotificationMailer).to receive(:send_en_instruction_notification).and_return(delivery)

        subject
        dossier.reload

        expect(dossier).to be_en_instruction
        expect(dossier.pending_correction?).to be_falsey
        expect(dossier.en_instruction_at).to within(5.seconds).of(Time.current)
        expect(dossier.traitements.last.browser_name).to eq('Unknown Browser')
      end
    end
  end

  describe '#submit_en_construction' do
    before { sign_in(user) }
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let(:types_de_champ_public) { [{ type: :text }] }
    let(:dossier) { create(:dossier, :en_construction, procedure:, user:) }
    let(:first_champ) { dossier.owner_editing_fork.champs_public.first }
    let(:anchor_to_first_champ) { controller.helpers.link_to I18n.t('views.users.dossiers.fix_champ'), modifier_dossier_path(anchor: first_champ.labelledby_id), class: 'error-anchor' }
    let(:value) { 'beautiful value' }
    let(:now) { Time.zone.parse('01/01/2100') }
    let(:payload) { { id: dossier.id } }

    before { dossier.owner_editing_fork }

    subject do
      Timecop.freeze(now) do
        post :submit_en_construction, params: payload
      end
    end

    context 'when the dossier cannot be updated by the user' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it 'redirects to the dossiers list' do
        subject

        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'when the update fails' do
      render_views

      before do
        expect_any_instance_of(Dossier).to receive(:validate).and_return(false)
        expect_any_instance_of(Dossier).to receive(:errors).and_return(
          [double(inner_error: double(base: first_champ), message: 'nop')]
        )

        subject
      end

      it { expect(response).to render_template(:modifier) }
    end

    context 'when a mandatory champ is missing' do
      let(:value) { nil }
      render_views
      let(:types_de_champ_public) { [{ type: :text, mandatory: true, libelle: 'l' }] }
      before { subject }

      it { expect(response).to render_template(:modifier) }
      it { expect(response.body).to have_content("doit être rempli") }
      it { expect(response.body).to have_link(first_champ.libelle, href: "##{first_champ.labelledby_id}") }
    end

    context 'when dossier has no champ' do
      let(:submit_payload) { { id: dossier.id } }

      it 'does not raise any errors' do
        subject

        expect(response).to redirect_to(dossier_path(dossier))
      end
    end

    context 'when dossier repetition had been removed in newer version' do
      let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:, user:) }
      let(:types_de_champ_public) { [{ type: :repetition, libelle: 'repetition', children: [{ type: :text, libelle: 'child' }] }] }
      let(:editing_fork) { dossier.owner_editing_fork }
      let(:champ_repetition) { editing_fork.champs.find(&:repetition?) }
      before do
        editing_fork

        procedure.draft_revision.remove_type_de_champ(editing_fork.champs.find(&:repetition?).stable_id)
        procedure.publish_revision!

        editing_fork.reload
        editing_fork.rebase!
      end
      let(:submit_payload) { { id: dossier.id } }

      it { expect { subject }.not_to raise_error }
    end

    context 'when dossier was already submitted' do
      before { post :submit_en_construction, params: payload }

      it 'redirects to the dossier' do
        subject

        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq("Les modifications ont déjà été déposées")
      end
    end

    context "when there are pending correction" do
      let!(:correction) { create(:dossier_correction, dossier: dossier) }

      subject { post :submit_en_construction, params: { id: dossier.id } }

      it "resolves correction automatically" do
        expect { subject }.to change { correction.reload.resolved_at }.to be_truthy
      end

      context 'when procedure has sva enabled' do
        let(:procedure) { create(:procedure, :sva) }
        let(:dossier) { create(:dossier, :en_construction, procedure:, user:) }
        let!(:correction) { create(:dossier_correction, dossier: dossier) }

        subject { post :submit_en_construction, params: { id: dossier.id, dossier: { pending_correction: pending_correction_value } } }

        context 'when resolving correction' do
          let(:pending_correction_value) { "1" }
          it 'passe automatiquement en instruction' do
            expect(dossier.pending_correction?).to be_truthy

            subject
            dossier.reload

            expect(dossier).to be_en_instruction
            expect(dossier.pending_correction?).to be_falsey
            expect(dossier.en_instruction_at).to within(5.seconds).of(Time.current)
          end
        end

        context 'when not resolving correction' do
          render_views

          let(:pending_correction_value) { "" }
          it 'does not passe automatiquement en instruction' do
            subject
            dossier.reload

            expect(dossier).to be_en_construction
            expect(dossier.pending_correction?).to be_truthy

            expect(response.body).to include("Cochez la case")
          end
        end
      end
    end
  end

  describe '#update brouillon' do
    before { sign_in(user) }

    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{}, { type: :piece_justificative }]) }
    let(:dossier) { create(:dossier, user:, procedure:) }
    let(:first_champ) { dossier.champs_public.first }
    let(:piece_justificative_champ) { dossier.champs_public.last }
    let(:value) { 'beautiful value' }
    let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
    let(:now) { Time.zone.parse('01/01/2100') }

    let(:submit_payload) do
      {
        id: dossier.id,
        dossier: {
          groupe_instructeur_id: dossier.groupe_instructeur_id,
          champs_public_attributes: {
            first_champ.public_id => {
              with_public_id: true,
              value: value
            },
            piece_justificative_champ.public_id => {
              with_public_id: true,
              piece_justificative_file: file
            }
          }
        }
      }
    end
    let(:payload) { submit_payload }

    subject do
      Timecop.freeze(now) do
        patch :update, params: payload, format: :turbo_stream
      end
    end

    context 'when the dossier cannot be updated by the user' do
      let(:dossier) { create(:dossier, :en_instruction, user:, procedure:) }

      it 'redirects to the dossiers list' do
        subject

        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'when dossier can be updated by the owner' do
      it 'updates the champs' do
        subject

        expect(response).to have_http_status(:ok)
        expect(dossier.reload.updated_at.year).to eq(2100)
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:brouillon))
      end

      context 'without new values for champs' do
        let(:submit_payload) do
          {
            id: dossier.id,
            dossier: {
              champs_public_attributes: { first_champ.public_id => { with_public_id: true } }
            }
          }
        end

        it "doesn't set last_champ_updated_at" do
          subject
          expect(dossier.reload.last_champ_updated_at).to eq(nil)
        end
      end
    end

    context 'when the user has an invitation but is not the owner' do
      let(:dossier) { create(:dossier, procedure: procedure) }
      let!(:invite) { create(:invite, dossier: dossier, user: user) }

      before { subject }

      it { expect(first_champ.reload.value).to eq('beautiful value') }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'decimal number champ separator' do
      let (:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :decimal_number }]) }
      let (:submit_payload) do
        {
          id: dossier.id,
          dossier: {
            champs_public_attributes: { first_champ.public_id => { with_public_id: true, value: value } }
          }
        }
      end

      context 'when spearator is dot' do
        let(:value) { '3.14' }

        it "saves the value" do
          subject
          expect(first_champ.reload.value).to eq('3.14')
        end
      end

      context 'when spearator is comma' do
        let(:value) { '3,14' }

        it "saves the value" do
          subject
          expect(first_champ.reload.value).to eq('3.14')
        end
      end
    end
  end

  describe '#update en_construction' do
    before { sign_in(user) }

    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{}, { type: :piece_justificative }]) }
    let!(:dossier) { create(:dossier, :en_construction, user:, procedure:) }
    let(:first_champ) { dossier.champs_public.first }
    let(:anchor_to_first_champ) { controller.helpers.link_to I18n.t('views.users.dossiers.fix_champ'), brouillon_dossier_path(anchor: first_champ.labelledby_id), class: 'error-anchor' }
    let(:piece_justificative_champ) { dossier.champs_public.last }
    let(:value) { 'beautiful value' }
    let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
    let(:now) { Time.zone.parse('01/01/2100') }

    let(:submit_payload) do
      {
        id: dossier.id,
        dossier: {
          groupe_instructeur_id: dossier.groupe_instructeur_id,
          champs_public_attributes: {
            first_champ.public_id => {
              with_public_id: true,
              value: value
            },
            piece_justificative_champ.public_id => {
              with_public_id: true,
              piece_justificative_file: file
            }
          }
        }
      }
    end
    let(:payload) { submit_payload }

    subject do
      Timecop.freeze(now) do
        patch :update, params: payload, format: :turbo_stream
      end
    end

    context 'when the dossier cannot be updated by the user' do
      let!(:dossier) { create(:dossier, :en_instruction, user:, procedure:) }

      it 'redirects to the dossiers list' do
        subject
        expect(response).to redirect_to(dossier_path(dossier))
        expect(flash.alert).to eq('Votre dossier ne peut plus être modifié')
      end
    end

    context 'when dossier can be updated by the owner' do
      it 'updates the champs' do
        subject
        expect(first_champ.reload.value).to eq('beautiful value')
        expect(piece_justificative_champ.reload.piece_justificative_file).to be_attached
      end

      it 'updates the dossier timestamps' do
        subject
        dossier.reload
        expect(dossier.updated_at).to eq(now)
        expect(dossier.last_champ_updated_at).to eq(now)
      end

      it 'updates the dossier state' do
        subject
        expect(dossier.reload.state).to eq(Dossier.states.fetch(:en_construction))
      end

      it { is_expected.to have_http_status(:ok) }

      context 'when only a single file champ are modified' do
        # A bug in ActiveRecord causes records changed through grand-parent <->  parent <-> child
        # relationships do not touch the grand-parent record on change.
        # This situation is hit when updating just the attachment of a champ (and not the
        # champ itself).
        #
        # This test ensures that, whatever workaround we wrote for this, it still works properly.
        #
        # See https://github.com/rails/rails/issues/26726
        let(:submit_payload) do
          {
            id: dossier.id,
            dossier: {
              champs_public_attributes: {
                piece_justificative_champ.public_id => {
                  with_public_id: true,
                  piece_justificative_file: file
                }
              }
            }
          }
        end

        it 'updates the dossier timestamps' do
          subject
          dossier.reload
          expect(dossier.updated_at).to eq(now)
          expect(dossier.last_champ_updated_at).to eq(now)
        end
      end
    end

    context 'when the update fails' do
      render_views

      context 'classic error' do
        before do
          expect_any_instance_of(Dossier).to receive(:save).and_return(false)
          expect_any_instance_of(Dossier).to receive(:errors).and_return(
            [message: 'nop', inner_error: double(base: first_champ)]
          )
          subject
        end

        it { expect(response).to render_template(:update) }

        it 'does not update the dossier timestamps' do
          dossier.reload
          expect(dossier.updated_at).not_to eq(now)
          expect(dossier.last_champ_updated_at).not_to eq(now)
        end

        it 'does not send an email' do
          expect(NotificationMailer).not_to receive(:send_en_construction_notification)

          subject
        end
      end

      context 'iban error' do
        let(:value) { 'abc' }

        before do
          first_champ.type_de_champ.update!(type_champ: :iban, mandatory: true, libelle: 'l')
          dossier.champs_public.first.becomes!(Champs::IbanChamp).save!

          subject
        end

        it { expect(response).to have_http_status(:success) }
      end
    end

    context 'when the user has an invitation but is not the owner' do
      let(:dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:invite) { create(:invite, dossier:, user:) }

      before { subject }

      it { expect(first_champ.reload.value).to eq('beautiful value') }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when the dossier is followed by an instructeur' do
      let(:dossier) { create(:dossier, procedure:) }
      let(:instructeur) { create(:instructeur) }
      let!(:invite) { create(:invite, dossier:, user:) }

      before do
        instructeur.follow(dossier)
      end

      it 'the follower has a notification' do
        expect(instructeur.reload.followed_dossiers.with_notifications).to eq([])
        subject
        expect(instructeur.reload.followed_dossiers.with_notifications).to eq([dossier.reload])
      end
    end

    context 'when the champ is a phone number' do
      let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :phone }]) }
      let!(:dossier) { create(:dossier, :en_construction, user:, procedure:) }
      let(:first_champ) { dossier.champs_public.first }
      let(:now) { Time.zone.parse('01/01/2100') }

      let(:submit_payload) do
        {
          id: dossier.id,
          dossier: {
            champs_public_attributes: {
              first_champ.public_id => {
                with_public_id: true,
                value: value
              }
            }
          }
        }
      end

      context 'with a valid value sent as string' do
        let(:value) { '0612345678' }
        it 'updates the value' do
          subject
          expect(first_champ.reload.value).to eq('0612345678')
        end
      end

      context 'with a valid value sent as number' do
        let(:value) { '45187272'.to_i }
        it 'updates the value' do
          subject
          expect(first_champ.reload.value).to eq('45187272')
        end
      end
    end
  end

  describe '#index' do
    before { sign_in(user) }

    context 'when the user does not have any dossiers' do
      before { get(:index) }

      it { expect(assigns(:statut)).to eq('en-cours') }
    end

    context 'when the user only have its own dossiers' do
      let!(:own_dossier) { create(:dossier, user: user) }

      before { get(:index) }
      it { expect(assigns(:statut)).to eq('en-cours') }
      it { expect(assigns(:user_dossiers)).to match([own_dossier]) }
    end

    context 'when the user only have some dossiers invites' do
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user) }

      before { get(:index) }

      it { expect(assigns(:statut)).to eq('dossiers-invites') }
      it { expect(assigns(:dossiers_invites)).to match([invite.dossier]) }
    end

    context 'when the user has dossiers invites, own and traites' do
      let!(:procedure) { create(:procedure, :published) }
      let!(:own_dossier) { create(:dossier, user: user) }
      let!(:own_dossier2) { create(:dossier, user: user, state: "accepte", procedure: procedure) }
      let!(:invite) { create(:invite, dossier: create(:dossier), user: user) }

      context 'and there is no statut param' do
        before { get(:index) }

        it { expect(assigns(:statut)).to eq('en-cours') }
      end

      context 'and there is "dossiers-invites" param' do
        before { get(:index, params: { statut: 'dossiers-invites' }) }

        it { expect(assigns(:statut)).to eq('dossiers-invites') }
      end

      context 'and there is "en-cours" param' do
        before { get(:index, params: { statut: 'en-cours' }) }

        it { expect(assigns(:statut)).to eq('en-cours') }
      end

      context 'and there is "traites" param' do
        before { get(:index, params: { statut: 'traites' }) }

        it { expect(assigns(:statut)).to eq('traites') }
      end

      context 'and the traité dossier has been hidden by user' do
        before do
          own_dossier2.update!(hidden_by_user_at: Time.zone.now)
          get(:index, params: { statut: 'traites' })
        end
        it { expect(assigns(:statut)).to eq('en-cours') }
      end

      context 'when the instructeur archive the dossier' do
        before do
          own_dossier2.update!(archived: true)
          get(:index, params: { statut: 'en-cours' })
        end
        it { expect(assigns(:statut)).to eq('en-cours') }
        it { expect(assigns(:dossiers_traites).map(&:id)).to eq([own_dossier2.id]) }
        it { expect(own_dossier2.archived).to be_truthy }
      end
    end

    context 'when the user has dossier in brouillon recently updated' do
      let!(:own_dossier) { create(:dossier, user: user) }
      let!(:own_dossier_2) { create(:dossier, user: user) }

      before { get(:index) }

      it { expect(assigns(:first_brouillon_recently_updated)).to match(own_dossier_2) }
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

    context 'when the user has a deleted dossier on a discarded procedure' do
      render_views

      let!(:deleted_dossier) { create(:deleted_dossier, user_id: user.id) }

      before { deleted_dossier.procedure.discard! }

      subject { get(:index, params: { statut: 'dossiers-supprimes-definitivement' }) }

      it { is_expected.to have_http_status(200) }
    end
  end

  describe '#show' do
    before do
      sign_in(user)
    end

    context 'with default output' do
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

    context "with PDF output" do
      let(:procedure) { create(:procedure) }
      let(:dossier) do
        create(:dossier,
               :accepte,
               :with_populated_champs,
               :with_motivation,
               :with_commentaires,
               procedure: procedure,
               user: user)
      end

      subject! { get(:show, params: { id: dossier.id, format: :pdf }) }

      context 'when the dossier is a brouillon' do
        let(:dossier) { create(:dossier, user: user) }
        it { is_expected.to redirect_to(brouillon_dossier_path(dossier)) }
      end

      context 'when the dossier has been submitted' do
        it { expect(assigns(:acls)).to eq(PiecesJustificativesService.new(user_profile: user).acl_for_dossier_export(dossier.procedure)) }
        it { expect(response).to render_template('dossiers/show') }
      end
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
    let(:instructeur_with_instant_message) { create(:instructeur) }
    let(:instructeur_without_instant_message) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure, user: user) }
    let(:saved_commentaire) { dossier.commentaires.first }
    let(:body) { "avant\napres" }
    let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
    let(:scan_result) { true }
    let(:now) { Time.zone.parse("18/09/1981") }

    subject {
      post :create_commentaire, params: {
        id: dossier.id,
        commentaire: {
          body: body,
          piece_jointe: file
        }
      }
    }

    before do
      Timecop.freeze(now)
      sign_in(user)
      allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
      allow(DossierMailer).to receive(:notify_new_commentaire_to_instructeur).and_return(double(deliver_later: nil))
      instructeur_with_instant_message.follow(dossier)
      instructeur_without_instant_message.follow(dossier)
      create(:assign_to, instructeur: instructeur_with_instant_message, procedure: procedure, instant_email_message_notifications_enabled: true)
      create(:assign_to, instructeur: instructeur_without_instant_message, procedure: procedure, instant_email_message_notifications_enabled: false)
    end

    after { Timecop.return }

    context 'commentaire creation' do
      it "creates a commentaire" do
        expect { subject }.to change(Commentaire, :count).by(1)

        expect(response).to redirect_to(messagerie_dossier_path(dossier))
        expect(DossierMailer).to have_received(:notify_new_commentaire_to_instructeur).with(dossier, instructeur_with_instant_message.email)
        expect(DossierMailer).not_to have_received(:notify_new_commentaire_to_instructeur).with(dossier, instructeur_without_instant_message.email)
        expect(flash.notice).to be_present
        expect(dossier.reload.last_commentaire_updated_at).to eq(now)
      end
    end

    context 'notify on new message to experts' do
      let(:expert) { create(:expert) }
      let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure, notify_on_new_message: true) }
      let(:avis) { create(:avis, dossier: dossier, claimant: instructeur_with_instant_message, experts_procedure: experts_procedure) }
      let(:avis2) { create(:avis, dossier: dossier, claimant: instructeur_with_instant_message, experts_procedure: experts_procedure) }

      context 'when notify_on_new_message is true' do
        before do
          allow(AvisMailer).to receive(:notify_new_commentaire_to_expert).and_return(double(deliver_later: nil))
          avis
          avis2
          subject
        end

        it 'sends just one email to the expert linked to several avis on the same dossier' do
          expect(AvisMailer).to have_received(:notify_new_commentaire_to_expert).with(dossier, avis, expert).once
        end
      end

      context 'when notify_on_new_message is false' do
        let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure, notify_on_new_message: false) }

        before do
          allow(AvisMailer).to receive(:notify_new_commentaire_to_expert).and_return(double(deliver_later: nil))
          avis
          avis2
          subject
        end

        it 'does not send any email to the expert' do
          expect(AvisMailer).not_to have_received(:notify_new_commentaire_to_expert)
        end
      end
    end

    context 'notification' do
      before 'instructeurs have no notification before the message' do
        expect(instructeur_with_instant_message.followed_dossiers.with_notifications).to eq([])
        expect(instructeur_without_instant_message.followed_dossiers.with_notifications).to eq([])
        Timecop.travel(now + 1.day)
        subject
      end

      it 'adds them a notification' do
        expect(instructeur_with_instant_message.reload.followed_dossiers.with_notifications).to eq([dossier.reload])
        expect(instructeur_without_instant_message.reload.followed_dossiers.with_notifications).to eq([dossier.reload])
      end
    end
  end

  describe "#papertrail" do
    before { sign_in(user) }

    subject do
      get :papertrail, format: :pdf, params: { id: dossier.id }
    end

    context 'when the dossier has been submitted' do
      let(:dossier) { create(:dossier, :en_construction, user: user) }

      it 'renders a PDF document' do
        subject
        expect(response).to render_template(:papertrail)
      end
    end

    context 'when the dossier is still a draft' do
      let(:dossier) { create(:dossier, :brouillon, user: user) }

      it 'raises an error' do
        expect { subject }.to raise_error(ActionController::BadRequest)
      end
    end
  end

  describe '#destroy' do
    before { sign_in(user) }

    subject { delete :destroy, params: { id: dossier.id } }

    shared_examples_for "the dossier can not be deleted" do
      it "doesn’t notify the deletion" do
        expect(DossierMailer).not_to receive(:notify_en_construction_deletion_to_administration)
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
        expect(DossierMailer).to receive(:notify_en_construction_deletion_to_administration).with(kind_of(Dossier), dossier.procedure.administrateurs.first.email).and_return(double(deliver_later: nil))
        subject
      end

      it "hide the dossier and does not create a deleted dossier" do
        procedure = dossier.procedure
        dossier_id = dossier.id
        subject
        expect(Dossier.find_by(id: dossier_id)).to be_present
        expect(Dossier.find_by(id: dossier_id).hidden_by_user_at).to be_present
        expect(procedure.deleted_dossiers.count).to eq(0)
      end

      it "fill hidden by reason" do
        subject
        expect(dossier.reload.hidden_by_reason).not_to eq(nil)
        expect(dossier.reload.hidden_by_reason).to eq("user_request")
      end

      it { is_expected.to redirect_to(dossiers_path) }

      context "and the instruction has started" do
        let(:dossier) { create(:dossier, :en_instruction, user: user, autorisation_donnees: true) }

        it_behaves_like "the dossier can not be deleted"
        it { is_expected.to redirect_to(dossiers_path) }
      end
    end

    context 'when dossier is not owned by signed in user' do
      let(:user2) { create(:user) }
      let(:dossier) { create(:dossier, user: user2, autorisation_donnees: true) }

      it_behaves_like "the dossier can not be deleted"
      it { is_expected.to redirect_to(root_path) }

      context 'but user is invited' do
        before { dossier.invites.create(user:, email: user.email, message: 'Salut', email_sender: user2.email) }

        it do
          procedure = dossier.procedure
          dossier_id = dossier.id

          expect(user.invite?(dossier)).to be_truthy
          is_expected.to redirect_to(dossiers_path)
          expect(Dossier.find_by(id: dossier_id)).to be_present
          expect(Dossier.find_by(id: dossier_id).hidden_by_user_at).to be_nil
          expect(procedure.deleted_dossiers.count).to eq(0)
          expect(user.invite?(dossier)).to be_falsy
        end
      end
    end
  end

  describe '#restore' do
    before { sign_in(user) }
    subject { patch :restore, params: { id: dossier.id } }

    context 'when the user want to restore his dossier' do
      let!(:dossier) { create(:dossier, :accepte, :with_individual, en_construction_at: Time.zone.yesterday.beginning_of_day.utc, hidden_by_user_at: Time.zone.yesterday.beginning_of_day.utc, user: user, autorisation_donnees: true) }

      before { subject }

      it 'must have hidden_by_user_at nil' do
        expect(dossier.reload.hidden_by_user_at).to be_nil
      end
    end
  end

  describe '#new' do
    let(:procedure) { create(:procedure, :published) }
    let(:procedure_id) { procedure.id }
    let(:params) { { procedure_id: procedure_id } }

    subject { get :new, params: params }

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
          it { expect { subject }.to change(Dossier, :count).by 1 }
          context 'when procedure is for entreprise' do
            it { is_expected.to redirect_to siret_dossier_path(id: Dossier.last) }
          end

          context 'when procedure is for particulier' do
            let(:procedure) { create(:procedure, :published, :for_individual) }
            it { is_expected.to redirect_to identite_dossier_path(id: Dossier.last) }
          end

          context 'when procedure is closed' do
            let(:procedure) { create(:procedure, :closed) }

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

  describe '#index' do
    before do
      sign_in(user)
    end
    it 'works' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#extend_conservation' do
    let(:procedure) { create(:procedure, duree_conservation_dossiers_dans_ds: 3) }
    let(:dossier) { create(:dossier, procedure: procedure, user: user) }
    subject { post :extend_conservation, params: { dossier_id: dossier.id } }
    context 'when user logged in' do
      before { sign_in(user) }
      it 'works' do
        expect(subject).to redirect_to(dossier_path(dossier))
      end

      it 'extends conservation_extension by duree_conservation_dossiers_dans_ds' do
        subject
        expect(dossier.reload.conservation_extension).to eq(procedure.duree_conservation_dossiers_dans_ds.months)
      end

      it 'flashed notice success' do
        subject
        expect(flash[:notice]).to eq(I18n.t('views.users.dossiers.archived_dossier', duree_conservation_dossiers_dans_ds: procedure.duree_conservation_dossiers_dans_ds))
      end
    end

    context 'when not logged in' do
      it 'fails' do
        subject
        expect { expect(response).to redirect_to(new_user_session_path) }
      end
    end
  end

  describe '#clone' do
    let(:procedure) { create(:procedure, :with_all_champs) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    subject { post :clone, params: { id: dossier.id } }

    context 'not signed in' do
      it { expect(subject).to redirect_to(new_user_session_path) }
    end

    context 'signed with user dossier' do
      before { sign_in dossier.user }

      it { expect(subject).to redirect_to(brouillon_dossier_path(Dossier.last)) }
      it { expect { subject }.to change { dossier.user.dossiers.count }.by(1) }
    end
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
